import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:impostor_ar/layers/data/repositories/game_repository.dart';
import 'package:impostor_ar/layers/data/repositories/auth_repository.dart';
import 'package:impostor_ar/layers/presentation/shared/widgets/pin_input.dart';
import 'package:impostor_ar/layers/presentation/shared/widgets/button_header.dart';
import 'package:impostor_ar/core/services/notification_service.dart';

class JoinRoomScreen extends StatefulWidget {
  final String? initialRoomCode;

  const JoinRoomScreen({super.key, this.initialRoomCode});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  late TextEditingController _roomCodeController;
  late FocusNode _pinFocusNode;
  bool _isJoining = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _pinFocusNode = FocusNode();
    _roomCodeController = TextEditingController(
      text: widget.initialRoomCode ?? '',
    );
    if (widget.initialRoomCode != null) {
      Future.microtask(() {
        if (mounted && !_isDisposed) {
          _joinRoom();
        }
      });
    } else {
      // Dar foco automático ao PinInput quando entrar na página
      Future.microtask(() {
        if (mounted && !_isDisposed) {
          _pinFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pinFocusNode.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    if (_roomCodeController.text.isEmpty) {
      GetIt.I<NotificationService>().showError(
        context,
        'Por favor, insira um código de sala.',
      );
      return;
    }

    setState(() => _isJoining = true);

    final gameRepository = GetIt.I<GameRepository>();
    final user = GetIt.I<AuthRepository>().currentUser;
    final roomCode = _roomCodeController.text.trim().toUpperCase();

    if (user != null) {
      final roomId = await gameRepository.getRoomIdByCode(roomCode);
      if (!mounted) return;

      if (roomId == null) {
        GetIt.I<NotificationService>().showError(
          context,
          'Sala não encontrada. Verifique o código.',
        );
        if (mounted) setState(() => _isJoining = false);
        return;
      }

      final success = await gameRepository.joinRoom(
        roomId,
        user.uid,
        user.displayName ?? 'Jogador',
        user.photoURL,
      );
      if (!mounted) return;

      if (success) {
        // Não fazer setState depois que vamos navegar
        context.go('/room/$roomCode');
      } else {
        // Verificar se foi banido, sala iniciada ou outro erro
        final room = await gameRepository.getRoomStream(roomId).first;
        if (!mounted) return;

        final isBanned = room?.bannedList.contains(user.uid) ?? false;
        final isGameStarted =
            room?.status.toString() == 'GameStatus.inProgress';

        if (isBanned) {
          GetIt.I<NotificationService>().showError(
            context,
            'Você foi banido desta sala.',
          );
        } else if (isGameStarted) {
          GetIt.I<NotificationService>().showError(
            context,
            'Esta sala já iniciou a partida. Não é possível entrar.',
          );
        } else {
          GetIt.I<NotificationService>().showError(
            context,
            'Não foi possível entrar na sala. A sala pode estar cheia.',
          );
        }

        if (mounted) setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrar em Sala'),
        centerTitle: true,
        actions: [
          ButtonHeader(
            icon: Icons.qr_code_scanner_outlined,
            onPressed: () => context.go('/qr-scanner'),
            tooltip: 'Escanear QR Code',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Código da Sala',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                PinInput(
                  length: 6,
                  controller: _roomCodeController,
                  focusNode: _pinFocusNode,
                  onComplete: (code) {
                    _roomCodeController.text = code;
                    // Entrar automaticamente ao completar o código
                    Future.microtask(() {
                      if (mounted) {
                        _joinRoom();
                      }
                    });
                  },
                ),
                const SizedBox(height: 28),
                _isJoining
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.door_front_door),
                        label: const Text('ENTRAR'),
                        onPressed: _joinRoom,
                        style: ElevatedButton.styleFrom(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
