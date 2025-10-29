import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:impostor_ar/layers/domain/models/game_room_model.dart';
import 'package:impostor_ar/layers/domain/models/player_model.dart';
import 'package:impostor_ar/layers/data/utils/room_code_generator.dart';
import 'package:impostor_ar/core/models/player_color.dart';
import 'dart:math';

class GameRepository {
  final FirebaseFirestore _firestore;

  GameRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('rooms');

  Future<String> createRoom({
    required String hostId,
    required String hostName,
    required String? hostPhoto,
    required int maxPlayers,
    required int numImpostors,
  }) async {
    try {
      String roomCode = generateRoomCode();

      while (await _codeExists(roomCode)) {
        roomCode = generateRoomCode();
      }

      // Determinar avatar inicial do host
      String initialAvatar;
      if (hostPhoto != null && hostPhoto.isNotEmpty) {
        initialAvatar = hostPhoto;
      } else {
        // Usar uma cor aleatória (Random() em vez de PlayerColor.random())
        final random = Random();
        initialAvatar =
            PlayerColor.values[random.nextInt(PlayerColor.values.length)].hex;
      }

      // Criar Player para o host
      final hostPlayer = Player(
        uid: hostId,
        name: hostName,
        userPhotoUrl: hostPhoto,
        avatar: initialAvatar,
        joinedAt: DateTime.now().millisecondsSinceEpoch,
      );

      // Criar players fake para testes
      final fakePlayers = _generateFakePlayers();

      final newRoom = GameRoom(
        id: '',
        code: roomCode,
        hostId: hostId,
        maxPlayers: maxPlayers,
        numImpostors: numImpostors,
        players: [hostPlayer, ...fakePlayers],
        status: GameStatus.waiting,
        createdAt: Timestamp.now(),
      );
      DocumentReference docRef = await _rooms.add(newRoom.toFirestore());
      return docRef.id;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao criar a sala: $e');
      return '';
    }
  }

  Future<bool> _codeExists(String code) async {
    try {
      final query = await _rooms.where('code', isEqualTo: code).limit(1).get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Stream<GameRoom?> getRoomStream(String roomId) {
    return _rooms.doc(roomId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return GameRoom.fromFirestore(snapshot);
      }
      return null;
    });
  }

  Future<String?> getRoomIdByCode(String code) async {
    try {
      final query = await _rooms.where('code', isEqualTo: code).limit(1).get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar sala pelo código: $e');
      return null;
    }
  }

  Stream<GameRoom?> getRoomStreamByCode(String code) {
    return _rooms.where('code', isEqualTo: code).limit(1).snapshots().map((
      snapshot,
    ) {
      if (snapshot.docs.isNotEmpty) {
        return GameRoom.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }

  Future<bool> joinRoom(
    String roomId,
    String userId,
    String playerName,
    String? playerPhoto,
  ) async {
    try {
      final room = await _rooms.doc(roomId).get();
      if (!room.exists) return false;

      final data = room.data() as Map<String, dynamic>;

      // Verificar se o jogo já iniciou
      final status = data['status'] as String? ?? 'waiting';
      if (status == 'inProgress' || status == 'finished') {
        return false;
      }

      // Verificar se o usuário está banido
      final bannedList = List<String>.from(data['banned'] ?? []);
      if (bannedList.contains(userId)) {
        // Usuário está banido
        return false;
      }

      final playersData = Map<String, dynamic>.from(data['players'] ?? {});

      // Determinar avatar inicial
      String initialAvatar;
      if (playerPhoto != null && playerPhoto.isNotEmpty) {
        // Se tem foto, usa foto como avatar inicial
        initialAvatar = playerPhoto;
      } else {
        // Se não tem foto, precisa escolher uma cor aleatória que não está sendo usada
        // Coletar cores já usadas
        final usedColors = <String>{};
        playersData.forEach((uid, playerData) {
          if (playerData is Map<String, dynamic>) {
            final avatar = playerData['avatar'] as String?;
            if (avatar != null &&
                RegExp(r'^[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$').hasMatch(avatar)) {
              usedColors.add(avatar);
            }
          }
        });

        // Encontrar cores disponíveis
        final availableColors = PlayerColor.values
            .where((color) => !usedColors.contains(color.hex))
            .toList();

        // Se houver cores disponíveis, escolher uma aleatória
        if (availableColors.isNotEmpty) {
          final random = Random();
          initialAvatar =
              availableColors[random.nextInt(availableColors.length)].hex;
        } else {
          // Fallback: se todas cores estão usadas, usar a primeira disponível (nunca deve chegar aqui com 12 cores e max 12 players)
          initialAvatar = PlayerColor.values.first.hex;
        }
      }

      // Criar novo Player
      final newPlayer = Player(
        uid: userId,
        name: playerName,
        userPhotoUrl: playerPhoto,
        avatar: initialAvatar,
        joinedAt: DateTime.now().millisecondsSinceEpoch,
      );

      playersData[userId] = newPlayer.toMap();

      // Verificar novamente se a cor ainda está disponível (case de race condition)
      // Se for cor e já estiver sendo usada por outro, tentar outra cor
      final isColor = RegExp(
        r'^[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$',
      ).hasMatch(initialAvatar);

      if (isColor) {
        // É uma cor hex
        bool colorAlreadyUsed = false;
        for (final entry in playersData.entries) {
          if (entry.key != userId) {
            final otherPlayerData = entry.value as Map<String, dynamic>;
            final otherAvatar = otherPlayerData['avatar'] as String?;
            if (otherAvatar == initialAvatar) {
              colorAlreadyUsed = true;
              break;
            }
          }
        }

        if (colorAlreadyUsed) {
          // Cor já foi usada, tentar encontrar outra
          final usedColorsNow = <String>{};
          playersData.forEach((uid, playerData) {
            if (playerData is Map<String, dynamic> && uid != userId) {
              final avatar = playerData['avatar'] as String?;
              if (avatar != null &&
                  RegExp(
                    r'^[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$',
                  ).hasMatch(avatar)) {
                usedColorsNow.add(avatar);
              }
            }
          });

          final availableColorsNow = PlayerColor.values
              .where((color) => !usedColorsNow.contains(color.hex))
              .toList();

          if (availableColorsNow.isNotEmpty) {
            final random = Random();
            initialAvatar =
                availableColorsNow[random.nextInt(availableColorsNow.length)]
                    .hex;
            playersData[userId] = newPlayer
                .copyWith(avatar: initialAvatar)
                .toMap();
          } else {
            // Sem cores disponíveis
            return false;
          }
        }
      }

      await _rooms.doc(roomId).update({'players': playersData});
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao entrar na sala: $e');
      return false;
    }
  }

  Future<bool> leaveRoom(String roomId, String userId) async {
    try {
      final room = await _rooms.doc(roomId).get();
      if (!room.exists) return false;

      final data = room.data() as Map<String, dynamic>;
      final playersData = Map<String, dynamic>.from(data['players'] ?? {});
      playersData.remove(userId);

      await _rooms.doc(roomId).update({'players': playersData});
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao sair da sala: $e');
      return false;
    }
  }

  Future<bool> deleteRoom(String roomId) async {
    try {
      await _rooms.doc(roomId).delete();
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao deletar a sala: $e');
      return false;
    }
  }

  Future<bool> updateRoom(String roomId, Map<String, dynamic> data) async {
    try {
      await _rooms.doc(roomId).update(data);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao atualizar a sala: $e');
      return false;
    }
  }

  Future<bool> updatePlayerColor(
    String roomId,
    String userId,
    String colorHex,
  ) async {
    try {
      final room = await _rooms.doc(roomId).get();
      if (!room.exists) return false;

      final data = room.data() as Map<String, dynamic>;
      final playersData = Map<String, dynamic>.from(data['players'] ?? {});

      if (!playersData.containsKey(userId)) return false;

      // Verificar se é uma cor (não foto) e se já está sendo usada por outro player
      final isColor = RegExp(
        r'^[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$',
      ).hasMatch(colorHex.replaceFirst('#', ''));

      if (isColor) {
        // Verificar se outro player já está usando esta cor
        for (final entry in playersData.entries) {
          if (entry.key != userId) {
            final otherPlayerData = entry.value as Map<String, dynamic>;
            final otherAvatar = otherPlayerData['avatar'] as String?;
            if (otherAvatar == colorHex) {
              // Cor já está em uso por outro player
              return false;
            }
          }
        }
      }

      // Atualizar o avatar do player para a cor
      final playerData = playersData[userId] as Map<String, dynamic>;
      playerData['avatar'] = colorHex;

      await _rooms.doc(roomId).update({'players': playersData});
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao atualizar avatar do jogador: $e');
      return false;
    }
  }

  Stream<bool> roomDeletedStream(String roomCode) {
    return _rooms.where('code', isEqualTo: roomCode).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.isEmpty;
    }).distinct();
  }

  Future<bool> kickPlayer(String roomId, String userId) async {
    return leaveRoom(roomId, userId);
  }

  Future<bool> banPlayer(String roomId, String userId) async {
    try {
      // Remover o jogador da sala
      await leaveRoom(roomId, userId);

      // Adicionar à lista de banidos
      final room = await _rooms.doc(roomId).get();
      if (!room.exists) return false;

      final data = room.data() as Map<String, dynamic>;
      final bannedList = List<String>.from(data['banned'] ?? []);

      if (!bannedList.contains(userId)) {
        bannedList.add(userId);
        await _rooms.doc(roomId).update({'banned': bannedList});
      }

      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao banir jogador: $e');
      return false;
    }
  }

  Future<bool> markPlayerReady(
    String roomId,
    String userId,
    bool isReady,
  ) async {
    try {
      await _rooms.doc(roomId).update({'players.$userId.isReady': isReady});
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao marcar jogador como pronto: $e');
      return false;
    }
  }

  Stream<bool> playerKickedStream(String roomCode, String userId) {
    return getRoomStreamByCode(roomCode)
        .map((room) {
          if (room == null) return false;
          return !room.players.any((player) => player.uid == userId);
        })
        .skip(1);
  }

  Future<bool> startGameCountdown(String roomId) async {
    try {
      await _rooms.doc(roomId).update({'countdownStartedAt': Timestamp.now()});
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao iniciar contagem: $e');
      return false;
    }
  }

  Future<bool> cancelGameCountdown(String roomId) async {
    try {
      await _rooms.doc(roomId).update({'countdownStartedAt': null});
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao cancelar contagem: $e');
      return false;
    }
  }

  Future<bool> initializeGame(String roomId) async {
    try {
      // ignore: avoid_print
      print('🎮 REPO: initializeGame chamado para roomId=$roomId');

      final roomDoc = await _rooms.doc(roomId).get();
      if (!roomDoc.exists) {
        // ignore: avoid_print
        print('🎮 REPO: Sala não existe!');
        return false;
      }

      final room = GameRoom.fromFirestore(roomDoc);
      // ignore: avoid_print
      print(
        '🎮 REPO: Sala encontrada com ${room.players.length} jogadores, numImpostors=${room.numImpostors}',
      );

      // Validar se tem jogadores suficientes (precisa ter pelo menos tantos jogadores quanto impostores)
      if (room.players.length < room.numImpostors) {
        // ignore: avoid_print
        print(
          '🎮 REPO: Não há jogadores suficientes! ${room.players.length} < ${room.numImpostors}',
        );
        return false;
      }

      // Selecionar impostores aleatoriamente
      final random = Random();
      final impostorIndices = <int>{};

      while (impostorIndices.length < room.numImpostors) {
        impostorIndices.add(random.nextInt(room.players.length));
      }

      final impostorIds = impostorIndices
          .map((index) => room.players[index].uid)
          .toList();

      // Atualizar sala com status inProgress e lista de impostores
      // ignore: avoid_print
      print(
        '🎮 REPO: Atualizando status para inProgress com impostorIds=$impostorIds',
      );

      await _rooms.doc(roomId).update({
        'status': 'inProgress',
        'impostorIds': impostorIds,
        'countdownStartedAt': null,
      });

      // ignore: avoid_print
      print('🎮 REPO: Status atualizado com sucesso!');

      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao inicializar jogo: $e');
      return false;
    }
  }

  /// Gera 2 players fake para testes
  List<Player> _generateFakePlayers() {
    final random = Random();
    final fakeNames = ['Bot Alex', 'Bot Luna', 'Bot Marco'];
    final usedColors = <String>{};

    final players = <Player>[];

    for (int i = 0; i < 3; i++) {
      // Selecionar cor não usada
      String color;
      do {
        color =
            PlayerColor.values[random.nextInt(PlayerColor.values.length)].hex;
      } while (usedColors.contains(color));
      usedColors.add(color);

      players.add(
        Player(
          uid: 'fake_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: fakeNames[i],
          userPhotoUrl: null,
          avatar: color,
          joinedAt: DateTime.now().millisecondsSinceEpoch,
          isReady: true, // Já marcados como prontos
        ),
      );
    }

    return players;
  }
}
