import 'package:cloud_firestore/cloud_firestore.dart';
import 'player_model.dart';

enum GameStatus { waiting, inProgress, finished }

class GameRoom {
  final String id; // ID único da sala (gerado pelo Firestore)
  final String code; // Código alfanumérico 6 dígitos (maiúsculo) para entrar
  final String hostId; // UID do jogador que criou a sala
  final int maxPlayers; // Número máximo de jogadores
  final int numImpostors; // Número de impostores
  final List<Player> players; // Lista de jogadores na sala
  final GameStatus status; // Status atual do jogo
  final Timestamp createdAt; // Quando a sala foi criada
  final List<String> bannedList; // Lista de UIDs banidos da sala
  final List<String> impostorIds; // UIDs dos impostores
  final Timestamp?
  countdownStartedAt; // Quando a contagem iniciou (null se não iniciada)

  GameRoom({
    required this.id,
    required this.code,
    required this.hostId,
    required this.maxPlayers,
    required this.numImpostors,
    required this.players,
    required this.status,
    required this.createdAt,
    this.bannedList = const [],
    this.impostorIds = const [],
    this.countdownStartedAt,
  });

  factory GameRoom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Converter dados players em List<Player>, mantendo a ordem de entrada
    List<Player> playersList = [];
    final playersData = data['players'] as Map<String, dynamic>? ?? {};

    // Ordenar por timestamp de entrada (joinedAt) se disponível
    final entries = playersData.entries.toList();
    entries.sort((a, b) {
      final aData = a.value as Map<String, dynamic>?;
      final bData = b.value as Map<String, dynamic>?;
      final aJoinedAt = aData?['joinedAt'] as int? ?? 0;
      final bJoinedAt = bData?['joinedAt'] as int? ?? 0;
      return aJoinedAt.compareTo(bJoinedAt);
    });

    for (final entry in entries) {
      final uid = entry.key;
      final playerData = entry.value;
      if (playerData is Map<String, dynamic>) {
        playersList.add(Player.fromMap({...playerData, 'uid': uid}));
      }
    }

    return GameRoom(
      id: doc.id,
      code: data['code'] ?? '',
      hostId: data['hostId'] ?? '',
      maxPlayers: data['maxPlayers'] ?? 10,
      numImpostors: data['numImpostors'] ?? 2,
      players: playersList,
      status: GameStatus.values.firstWhere(
        (e) => e.toString() == 'GameStatus.' + (data['status'] ?? 'waiting'),
        orElse: () => GameStatus.waiting,
      ),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      bannedList: List<String>.from(data['banned'] ?? []),
      impostorIds: List<String>.from(data['impostorIds'] ?? []),
      countdownStartedAt: data['countdownStartedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    // Converter List<Player> para Map para Firebase (organizado por uid)
    Map<String, dynamic> playersData = {};
    for (final player in players) {
      playersData[player.uid] = player.toMap();
    }

    return {
      'code': code,
      'hostId': hostId,
      'maxPlayers': maxPlayers,
      'numImpostors': numImpostors,
      'players': playersData,
      'status': status.toString().split('.').last,
      'createdAt': createdAt,
      'banned': bannedList,
      'impostorIds': impostorIds,
      'countdownStartedAt': countdownStartedAt,
    };
  }
}
