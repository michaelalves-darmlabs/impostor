import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:impostor_ar/core/providers/game_providers.dart';
import 'package:impostor_ar/layers/data/repositories/auth_repository.dart';
import 'package:impostor_ar/core/services/room_session_service.dart';
import 'package:impostor_ar/core/services/notification_service.dart';
import 'package:impostor_ar/layers/domain/models/game_room_model.dart';
import 'package:impostor_ar/layers/presentation/game/widgets/room_app_bar.dart';
import 'package:impostor_ar/layers/presentation/game/widgets/players_list.dart';
import 'package:impostor_ar/layers/presentation/game/widgets/room_modals.dart';
import 'package:impostor_ar/layers/presentation/game/widgets/synchronized_countdown_modal.dart';
import 'package:impostor_ar/layers/presentation/game/screens/game_start_screen.dart';
import 'package:get_it/get_it.dart';

class RoomScreenGuest extends ConsumerStatefulWidget {
  final String roomCode;
  const RoomScreenGuest({super.key, required this.roomCode});

  @override
  ConsumerState<RoomScreenGuest> createState() => _RoomScreenGuestState();
}

class _RoomScreenGuestState extends ConsumerState<RoomScreenGuest> {
  late GoRouter _router;
  bool _isNavigatingAway = false;
  bool _hasJoined = false;

  @override
  void initState() {
    super.initState();
    _router = GoRouter.of(context);
    final roomSessionService = GetIt.I<RoomSessionService>();
    roomSessionService.setRoomCode(widget.roomCode);

    // Auto-join ao acessar por deeplink
    Future.microtask(() async {
      if (!_hasJoined && mounted) {
        _hasJoined = true;
        final currentUser = GetIt.I<AuthRepository>().currentUser;
        if (currentUser?.uid != null) {
          try {
            final roomId = await ref
                .read(gameRepositoryProvider)
                .getRoomIdByCode(widget.roomCode);
            if (roomId != null && mounted) {
              final success = await ref
                  .read(gameRepositoryProvider)
                  .joinRoom(
                    roomId,
                    currentUser!.uid,
                    currentUser.displayName ?? 'Jogador',
                    currentUser.photoURL,
                  );

              // Se falhou ao entrar, verificar se é por banimento
              if (!success && mounted) {
                final room = await ref
                    .read(gameRepositoryProvider)
                    .getRoomStream(roomId)
                    .first;

                if (room?.bannedList.contains(currentUser.uid) ?? false) {
                  _isNavigatingAway = true;
                  GetIt.I<NotificationService>().showError(
                    context,
                    'Você foi banido desta sala.',
                  );
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      GetIt.I<RoomSessionService>().clearRoomCode();
                      _router.go('/home');
                    }
                  });
                }
              }
            }
          } catch (e) {
            // Erro ao entrar
          }
        }
      }
    });
  }

  @override
  void dispose() {
    GetIt.I<RoomSessionService>().clearRoomCode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = GetIt.I<AuthRepository>().currentUser;
    final roomAsync = ref.watch(roomStreamProvider(widget.roomCode));

    // Monitorar kick do jogador
    ref.listen(
      playerKickedStreamProvider((
        roomCode: widget.roomCode,
        userId: currentUser?.uid ?? '',
      )),
      (previous, next) {
        next.whenData((isKicked) {
          if (isKicked && mounted && !_isNavigatingAway) {
            _isNavigatingAway = true;
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                GetIt.I<RoomSessionService>().clearRoomCode();
                _router.go('/home');
              }
            });
          }
        });
      },
    );

    // Monitorar quando countdown começa (sincronizado)
    ref.listen(countdownStreamProvider(widget.roomCode), (previous, next) {
      // ignore: avoid_print
      print(
        '🎮 GUEST: countdown listener acionado! previous=$previous, next=$next',
      );

      next.whenData((countdownActive) {
        // ignore: avoid_print
        print(
          '🎮 GUEST: countdownActive=$countdownActive, mounted=$mounted, _isNavigatingAway=$_isNavigatingAway',
        );
        if (countdownActive && mounted && !_isNavigatingAway) {
          _isNavigatingAway = true;
          Future.microtask(() {
            if (mounted) {
              final room = ref.read(roomStreamProvider(widget.roomCode)).value;
              // ignore: avoid_print
              print(
                '🎮 GUEST: mostrando countdown sincronizado, room=${room?.id}, countdownStartedAt=${room?.countdownStartedAt}',
              );
              if (room != null) {
                _showCountdownForGuest(context, room, currentUser?.uid ?? '');
              }
            }
          });
        }
      });
    });

    // Monitorar quando todos estão prontos (host inicia automaticamente)
    ref.listen(allPlayersReadyStreamProvider(widget.roomCode), (
      previous,
      next,
    ) {
      next.whenData((allReady) {
        // ignore: avoid_print
        print('🎮 GUEST: Todos prontos? $allReady');
        if (allReady && mounted && !_isNavigatingAway) {
          // Notificar para trigger de countdown
          // O host verá e iniciará automaticamente
        }
      });
    });

    return roomAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Sala')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: Center(child: Text('Erro: $error')),
      ),
      data: (room) {
        if (room == null) {
          if (!_isNavigatingAway) {
            _isNavigatingAway = true;
            Future.microtask(() {
              if (mounted) {
                GetIt.I<RoomSessionService>().clearRoomCode();
                context.go('/home');
              }
            });
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Carregando')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: RoomAppBar(
            roomCode: room.code,
            onBackPressed: () => _showLeaveRoomDialog(context, room),
            onShare: () => RoomModals.showShareMenu(
              context,
              room.code,
              () => RoomModals.showQrCode(context, room.code),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jogadores:',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${room.players.length}/${room.maxPlayers}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: PlayersList(
                    room: room,
                    gameRepository: ref.watch(gameRepositoryProvider),
                    showKickButton: false,
                  ),
                ),
                const SizedBox(height: 16),
                _buildReadyButton(context, room, currentUser),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLeaveRoomDialog(BuildContext context, GameRoom room) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da Sala?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final currentUser = GetIt.I<AuthRepository>().currentUser;
                if (currentUser?.uid != null) {
                  await ref
                      .read(gameRepositoryProvider)
                      .leaveRoom(room.id, currentUser!.uid);
                }
              } catch (e) {
                // Erro ao sair
              }
              if (mounted) {
                GetIt.I<RoomSessionService>().clearRoomCode();
                _router.go('/home');
              }
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  void _showCountdownForGuest(
    BuildContext context,
    GameRoom room,
    String currentUserId,
  ) {
    // ignore: avoid_print
    print('🎮 GUEST: _showCountdownForGuest chamado');
    // Mostrar countdown sincronizado (sem botão de cancelar)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SynchronizedCountdownModal(
        roomCode: room.code,
        showCancelButton: false, // Guest não pode cancelar
        onCountdownComplete: () {
          Navigator.of(context).pop();
          // Levar para tela de start
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  GameStartScreen(room: room, currentUserId: currentUserId),
            ),
          );
        },
        onCountdownCancelled: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildReadyButton(
    BuildContext context,
    GameRoom room,
    dynamic currentUser, // User? do Firebase
  ) {
    if (currentUser == null) return const SizedBox.shrink();

    // Encontrar o jogador atual na sala
    final currentPlayer =
        room.players.cast<dynamic>().firstWhere(
              (p) => p.uid == currentUser.uid,
              orElse: () => null,
            )
            as dynamic;

    if (currentPlayer == null) return const SizedBox.shrink();

    return ElevatedButton(
      onPressed: () =>
          _toggleReadyStatus(room, currentUser, !currentPlayer.isReady),
      style: ElevatedButton.styleFrom(
        backgroundColor: currentPlayer.isReady ? Colors.red : Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 22),
      ),
      child: Text(currentPlayer.isReady ? 'Não estou pronto' : 'Estou Pronto'),
    );
  }

  Future<void> _toggleReadyStatus(
    GameRoom room,
    dynamic currentUser, // User? do Firebase
    bool newReadyStatus,
  ) async {
    try {
      final gameRepository = ref.read(gameRepositoryProvider);
      await gameRepository.markPlayerReady(
        room.id,
        currentUser.uid,
        newReadyStatus,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao atualizar status de pronto: $e');
    }
  }
}
