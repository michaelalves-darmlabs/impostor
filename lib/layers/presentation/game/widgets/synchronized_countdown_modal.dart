import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:impostor_ar/core/providers/game_providers.dart';
import 'dart:async';

/// Modal de countdown sincronizado para host e guest
/// Escuta o timestamp do Firebase e calcula o tempo restante
class SynchronizedCountdownModal extends ConsumerStatefulWidget {
  final String roomCode;
  final VoidCallback onCountdownComplete;
  final VoidCallback onCountdownCancelled;
  final bool showCancelButton; // true para host, false para guest

  const SynchronizedCountdownModal({
    Key? key,
    required this.roomCode,
    required this.onCountdownComplete,
    required this.onCountdownCancelled,
    this.showCancelButton = true,
  }) : super(key: key);

  @override
  ConsumerState<SynchronizedCountdownModal> createState() =>
      _SynchronizedCountdownModalState();
}

class _SynchronizedCountdownModalState
    extends ConsumerState<SynchronizedCountdownModal> {
  Timer? _updateTimer;
  int _secondsRemaining = 10;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _startUpdateTimer();
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // Assistir ao provider de countdown para pegar o timestamp
      ref.watch(roomStreamProvider(widget.roomCode)).whenData((room) {
        if (room?.countdownStartedAt != null && mounted) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final startedAt = room!.countdownStartedAt!.millisecondsSinceEpoch;
          final elapsed = now - startedAt;
          final seconds = 10 - (elapsed ~/ 1000);

          setState(() {
            _secondsRemaining = seconds > 0 ? seconds : 0;
          });

          // ignore: avoid_print
          print(
            '🎯 SYNC COUNTDOWN: elapsed=${elapsed}ms, seconds=$_secondsRemaining',
          );

          // Quando termina
          if (_secondsRemaining <= 0 && !_completed) {
            _completed = true;
            _updateTimer?.cancel();
            // ignore: avoid_print
            print('🎯 SYNC COUNTDOWN: Contagem concluída!');
            widget.onCountdownComplete();
          }
        }
      });
    });
  }

  void _cancelCountdown() {
    _updateTimer?.cancel();
    widget.onCountdownCancelled();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.7),
        body: Center(
          child: GestureDetector(
            onTap: () {},
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'A partida vai começar em...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Text(
                        _secondsRemaining.toString(),
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  if (widget.showCancelButton)
                    ElevatedButton.icon(
                      onPressed: _cancelCountdown,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar Contagem'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 22,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
