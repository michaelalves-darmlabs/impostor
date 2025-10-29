import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:impostor_ar/core/services/notification_service.dart';
import 'package:impostor_ar/layers/data/repositories/game_repository.dart';
import 'package:impostor_ar/layers/domain/models/game_room_model.dart';

class SettingsMenuContent extends StatefulWidget {
  final GameRepository gameRepository;
  final String roomId;
  final GameRoom initialRoom;

  const SettingsMenuContent({
    required this.gameRepository,
    required this.roomId,
    required this.initialRoom,
  });

  @override
  State<SettingsMenuContent> createState() => _SettingsMenuContentState();
}

class _SettingsMenuContentState extends State<SettingsMenuContent> {
  late int maxPlayers;
  late int numImpostors;

  @override
  void initState() {
    super.initState();
    maxPlayers = widget.initialRoom.maxPlayers;
    numImpostors = widget.initialRoom.numImpostors;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Configurações da Sala',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Máximo de Jogadores'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: maxPlayers > 2
                          ? () async {
                              final newValue = maxPlayers - 1;
                              await _updateMaxPlayers(newValue);
                              if (mounted) {
                                setState(() => maxPlayers = newValue);
                              }
                            }
                          : null,
                    ),
                    Text('$maxPlayers', style: const TextStyle(fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: maxPlayers < 12
                          ? () async {
                              final newValue = maxPlayers + 1;
                              await _updateMaxPlayers(newValue);
                              if (mounted) {
                                setState(() => maxPlayers = newValue);
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Número de Impostores'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: numImpostors > 1
                          ? () async {
                              final newValue = numImpostors - 1;
                              await _updateNumImpostors(newValue);
                              if (mounted) {
                                setState(() => numImpostors = newValue);
                              }
                            }
                          : null,
                    ),
                    Text('$numImpostors', style: const TextStyle(fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: numImpostors < 3
                          ? () async {
                              final newValue = numImpostors + 1;
                              await _updateNumImpostors(newValue);
                              if (mounted) {
                                setState(() => numImpostors = newValue);
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 22),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.close_rounded),
                label: const Text('Fechar'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMaxPlayers(int newValue) async {
    try {
      await widget.gameRepository.updateRoom(widget.roomId, {
        'maxPlayers': newValue,
      });
    } catch (e) {
      if (mounted) {
        GetIt.I<NotificationService>().showError(
          context,
          'Erro ao atualizar máximo de jogadores',
        );
      }
    }
  }

  Future<void> _updateNumImpostors(int newValue) async {
    try {
      await widget.gameRepository.updateRoom(widget.roomId, {
        'numImpostors': newValue,
      });
    } catch (e) {
      if (mounted) {
        GetIt.I<NotificationService>().showError(
          context,
          'Erro ao atualizar número de impostores',
        );
      }
    }
  }
}
