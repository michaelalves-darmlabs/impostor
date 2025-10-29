import 'package:riverpod/riverpod.dart';
import 'package:impostor_ar/layers/data/repositories/game_repository.dart';
import 'package:impostor_ar/layers/domain/models/game_room_model.dart';
import 'package:get_it/get_it.dart';

// Providers para gerenciar estado do jogo

final gameRepositoryProvider = Provider((ref) => GetIt.I<GameRepository>());

final roomStreamProvider = StreamProvider.family<GameRoom?, String>((
  ref,
  roomCode,
) {
  final gameRepository = ref.watch(gameRepositoryProvider);
  return gameRepository.getRoomStreamByCode(roomCode);
});

final playerKickedStreamProvider =
    StreamProvider.family<bool, ({String roomCode, String userId})>((
      ref,
      params,
    ) {
      final gameRepository = ref.watch(gameRepositoryProvider);
      return gameRepository.playerKickedStream(params.roomCode, params.userId);
    });

final gameStartedStreamProvider = StreamProvider.family<bool, String>((
  ref,
  roomCode,
) {
  final gameRepository = ref.watch(gameRepositoryProvider);
  return gameRepository.getRoomStreamByCode(roomCode).map((room) {
    final statusStr = room?.status.toString() ?? 'null';
    final isInProgress = statusStr == 'GameStatus.inProgress';
    // ignore: avoid_print
    print(
      '🎮 PROVIDER: gameStartedStream - statusStr=$statusStr, isInProgress=$isInProgress, room.id=${room?.id}',
    );
    return isInProgress;
  }).distinct();
});

final allPlayersReadyStreamProvider = StreamProvider.family<bool, String>((
  ref,
  roomCode,
) {
  final gameRepository = ref.watch(gameRepositoryProvider);
  return gameRepository.getRoomStreamByCode(roomCode).map((room) {
    if (room == null || room.players.isEmpty) return false;
    // Todos prontos: todos os jogadores EXCETO o HOST têm isReady = true
    final guestsReady = room.players
        .where((player) => player.uid != room.hostId)
        .every((player) => player.isReady);
    // ignore: avoid_print
    print('🎮 PROVIDER: allPlayersReady=$guestsReady (guests/jogadores)');
    return guestsReady;
  }).distinct();
});

class RoomController extends Notifier<AsyncValue<GameRoom?>> {
  late final GameRepository _gameRepository;

  @override
  AsyncValue<GameRoom?> build() {
    _gameRepository = ref.watch(gameRepositoryProvider);
    // Pega o roomCode via família
    return const AsyncValue.loading();
  }

  void initialize(String roomCode) {
    ref.listen(roomStreamProvider(roomCode), (previous, next) {
      state = next;
    });
    state = ref.watch(roomStreamProvider(roomCode));
  }

  Future<void> updateMaxPlayers(int newValue) async {
    final room = state.value;
    if (room != null) {
      try {
        await _gameRepository.updateRoom(room.id, {'maxPlayers': newValue});
      } catch (e) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> updateNumImpostors(int newValue) async {
    final room = state.value;
    if (room != null) {
      try {
        await _gameRepository.updateRoom(room.id, {'numImpostors': newValue});
      } catch (e) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> kickPlayer(String userId) async {
    final room = state.value;
    if (room != null) {
      try {
        await _gameRepository.kickPlayer(room.id, userId);
      } catch (e) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> deleteRoom() async {
    final room = state.value;
    if (room != null) {
      try {
        await _gameRepository.deleteRoom(room.id);
      } catch (e) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> leaveRoom(String userId) async {
    final room = state.value;
    if (room != null) {
      try {
        await _gameRepository.leaveRoom(room.id, userId);
      } catch (e) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }
}

final roomControllerProvider =
    NotifierProvider<RoomController, AsyncValue<GameRoom?>>(RoomController.new);

/// Provider que controla o countdown sincronizado via Firebase
/// Retorna true se o countdown está ativo
final countdownStreamProvider = StreamProvider.family<bool, String>((
  ref,
  roomCode,
) {
  final gameRepository = ref.watch(gameRepositoryProvider);
  return gameRepository.getRoomStreamByCode(roomCode).map((room) {
    final hasCountdown = room?.countdownStartedAt != null;
    // ignore: avoid_print
    print(
      '🎮 PROVIDER: countdownStream - hasCountdown=$hasCountdown, countdownStartedAt=${room?.countdownStartedAt}',
    );
    return hasCountdown;
  }).distinct();
});
