import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:impostor_ar/core/providers/game_providers.dart';
import 'package:impostor_ar/core/services/room_session_service.dart';
import 'package:impostor_ar/core/services/notification_service.dart';
import 'package:impostor_ar/layers/data/repositories/auth_repository.dart';
import 'package:impostor_ar/layers/domain/models/game_room_model.dart';
import 'package:impostor_ar/layers/presentation/game/widgets/room_app_bar.dart';
import 'package:impostor_ar/layers/presentation/game/widgets/players_list.dart';
import 'package:impostor_ar/layers/presentation/game/widgets/room_modals.dart';
import 'package:impostor_ar/layers/presentation/game/widgets/room_settings_dropdown.dart';
import 'package:impostor_ar/layers/presentation/game/widgets/synchronized_countdown_modal.dart';
import 'package:impostor_ar/layers/presentation/game/screens/game_start_screen.dart';
import 'package:get_it/get_it.dart';

class RoomScreenHost extends ConsumerStatefulWidget {
  final String roomCode;
  const RoomScreenHost({super.key, required this.roomCode});

  @override
  ConsumerState<RoomScreenHost> createState() => _RoomScreenHostState();
}

class _RoomScreenHostState extends ConsumerState<RoomScreenHost> {
  late GoRouter _router;
  bool _autoStarted = false;

  @override
  void initState() {
    super.initState();
    _router = GoRouter.of(context);
    GetIt.I<RoomSessionService>().setRoomCode(widget.roomCode);
  }

  @override
  void dispose() {
    GetIt.I<RoomSessionService>().clearRoomCode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomStreamProvider(widget.roomCode));

    // Monitorar quando todos os jogadores estão prontos - AUTO START
    ref.listen(allPlayersReadyStreamProvider(widget.roomCode), (
      previous,
      next,
    ) {
      next.whenData((allReady) {
        // ignore: avoid_print
        print('🎮 HOST: Todos prontos? $allReady');

        // Se todos prontos E ainda não iniciou E tem sala atual
        if (allReady && !_autoStarted && mounted) {
          _autoStarted = true;
          // ignore: avoid_print
          print('🎮 HOST: AUTO-INICIANDO COUNTDOWN!');

          // Pegar a sala atual
          final currentRoom = roomAsync.maybeWhen(
            data: (room) => room,
            orElse: () => null,
          );

          if (currentRoom != null) {
            Future.microtask(() {
              if (mounted) {
                _startGameCountdown(context, currentRoom, ref);
              }
            });
          }
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
          return Scaffold(
            appBar: AppBar(title: const Text('Sala não encontrada')),
            body: const Center(
              child: Text('Sala não encontrada ou foi deletada.'),
            ),
          );
        }

        return Scaffold(
          appBar: RoomAppBar(
            roomCode: room.code,
            showSettings: true,
            onBackPressed: () => _showCloseRoomDialog(context, room),
            onShare: () => RoomModals.showShareMenu(
              context,
              room.code,
              () => RoomModals.showQrCode(context, room.code),
            ),
            onSettings: () {
              final gameRepo = ref.read(gameRepositoryProvider);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) =>
                    RoomSettingsDropdown(room: room, gameRepository: gameRepo),
              );
            },
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
                    showKickButton: true,
                    onKickPlayer: (roomId, userId, playerName) =>
                        _showKickConfirmDialog(
                          context,
                          roomId,
                          userId,
                          playerName,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('INICIAR JOGO'),
                  onPressed: _allPlayersReady(room)
                      ? () {
                          _startGameCountdown(context, room, ref);
                        }
                      : null,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCloseRoomDialog(BuildContext context, GameRoom room) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fechar Sala?'),
        content: const Text('Tem certeza que deseja fechar a sala?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(gameRepositoryProvider).deleteRoom(room.id);
              } catch (e) {
                // Erro ao deletar
              }
              if (mounted) {
                GetIt.I<RoomSessionService>().clearRoomCode();
                _router.go('/home');
              }
            },
            child: const Text('Fechar Sala'),
          ),
        ],
      ),
    );
  }

  void _showKickConfirmDialog(
    BuildContext context,
    String roomId,
    String userId,
    String playerName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover Jogador?'),
        content: Text('Tem certeza que deseja remover $playerName da sala?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref
                    .read(gameRepositoryProvider)
                    .kickPlayer(roomId, userId);
              } catch (e) {
                // Erro ao kickar
              }
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  Future<void> _startGameCountdown(
    BuildContext context,
    GameRoom room,
    WidgetRef ref,
  ) async {
    // Validar mínimo de jogadores (mínimo 3 para gameplay interessante: 1 impostor + 2 crewmates)
    const minPlayers = 3;
    if (room.players.length < minPlayers) {
      GetIt.I<NotificationService>().showError(
        context,
        'Mínimo de $minPlayers jogadores necessário! Você tem ${room.players.length}.',
      );
      return;
    }

    // Validar se todos estão prontos
    if (!_allPlayersReady(room)) {
      GetIt.I<NotificationService>().showError(
        context,
        'Todos os jogadores devem estar prontos para iniciar!',
      );
      return;
    }

    // Iniciar contagem no Firebase
    final gameRepo = ref.read(gameRepositoryProvider);
    final currentUser = GetIt.I<AuthRepository>().currentUser;

    try {
      await gameRepo.startGameCountdown(room.id);

      if (!context.mounted) return;

      // Capturar context da tela (não do dialog)
      final screenContext = context;

      // Mostrar modal de contagem sincronizado
      await showDialog(
        context: screenContext,
        barrierDismissible: false,
        builder: (dialogContext) => SynchronizedCountdownModal(
          roomCode: widget.roomCode,
          onCountdownComplete: () async {
            // ignore: avoid_print
            print('🎮 HOST: onCountdownComplete callback chamado!');

            // Fechar o modal
            Navigator.of(dialogContext).pop();
            // ignore: avoid_print
            print('🎮 HOST: Modal fechado');

            // Pequeno delay para garantir que o modal foi fechado
            await Future.delayed(const Duration(milliseconds: 300));

            // Inicializar jogo
            // ignore: avoid_print
            print('🎮 HOST: Iniciando initializeGame...');
            final success = await gameRepo.initializeGame(room.id);
            // ignore: avoid_print
            print('🎮 HOST: initializeGame resultado: $success');

            // Aguardar mais tempo para os dados serem atualizados no Firebase
            // ignore: avoid_print
            print('🎮 HOST: Aguardando 2s para Firebase replicar...');
            await Future.delayed(const Duration(seconds: 2));

            // Pegar dados atualizados da sala
            // ignore: avoid_print
            print('🎮 HOST: Buscando sala atualizada...');
            final updatedRoom = await gameRepo.getRoomStream(room.id).first;
            // ignore: avoid_print
            print(
              '🎮 HOST: Sala atualizada: status=${updatedRoom?.status}, impostorIds=${updatedRoom?.impostorIds}',
            );

            if (updatedRoom != null) {
              // ignore: avoid_print
              print(
                '🎮 HOST: Navegando para GameStartScreen via screenContext',
              );
              // Navegar usando screenContext (context da tela, não do dialog)
              Navigator.of(screenContext).push(
                PageRouteBuilder(
                  opaque: true,
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      GameStartScreen(
                        room: updatedRoom,
                        currentUserId: currentUser?.uid ?? '',
                      ),
                ),
              );
            } else {
              // ignore: avoid_print
              print('🎮 HOST: updatedRoom é null!');
            }
          },
          onCountdownCancelled: () async {
            await gameRepo.cancelGameCountdown(room.id);
          },
        ),
      );
    } catch (e) {
      if (context.mounted) {
        GetIt.I<NotificationService>().showError(
          context,
          'Erro ao iniciar contagem: $e',
        );
      }
    }
  }

  bool _allPlayersReady(GameRoom room) {
    if (room.players.isEmpty) return false;
    // Todos exceto o host devem estar prontos
    return room.players
        .where((player) => player.uid != room.hostId)
        .every((player) => player.isReady);
  }
}
