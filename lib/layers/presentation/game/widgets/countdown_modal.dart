import 'package:flutter/material.dart';
import 'dart:async';

class CountdownModal extends StatefulWidget {
  final String roomId;
  final String hostId;
  final String currentUserId;
  final VoidCallback onCountdownComplete;
  final VoidCallback onCountdownCancelled;

  const CountdownModal({
    Key? key,
    required this.roomId,
    required this.hostId,
    required this.currentUserId,
    required this.onCountdownComplete,
    required this.onCountdownCancelled,
  }) : super(key: key);

  @override
  State<CountdownModal> createState() => _CountdownModalState();
}

class _CountdownModalState extends State<CountdownModal> {
  late Timer _timer;
  int _secondsRemaining = 10;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    // ignore: avoid_print
    print('🎯 COUNTDOWN: Iniciando contagem com $_secondsRemaining segundos');
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // ignore: avoid_print
      print('🎯 COUNTDOWN: Tick - $_secondsRemaining segundos restantes');
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          // ignore: avoid_print
          print(
            '🎯 COUNTDOWN: Contagem concluída! Chamando onCountdownComplete()',
          );
          _timer.cancel();
          widget.onCountdownComplete();
        }
      });
    });
  }

  void _cancelCountdown() {
    if (widget.currentUserId != widget.hostId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apenas o anfitrião pode cancelar a contagem'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _timer.cancel();

    widget.onCountdownCancelled();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHost = widget.currentUserId == widget.hostId;

    return WillPopScope(
      onWillPop: () async => false, // Impede fechamento com back button
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.7),
        body: Center(
          child: GestureDetector(
            onTap: () {}, // Impede interações fora do modal
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Título
                  const Text(
                    'A partida vai começar em...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Contagem regressiva grande
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
                  // Botão cancelar (só anfitrião)
                  if (isHost)
                    ElevatedButton.icon(
                      onPressed: _cancelCountdown,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar Contagem'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Apenas o anfitrião pode cancelar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade300,
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
