import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:impostor_ar/core/services/notification_service.dart';
import 'package:impostor_ar/layers/data/repositories/game_repository.dart';
import 'package:impostor_ar/layers/domain/models/game_room_model.dart';

class RoomSettingsDropdown extends StatefulWidget {
  final GameRoom room;
  final GameRepository gameRepository;

  const RoomSettingsDropdown({
    super.key,
    required this.room,
    required this.gameRepository,
  });

  @override
  State<RoomSettingsDropdown> createState() => _RoomSettingsDropdownState();
}

class _RoomSettingsDropdownState extends State<RoomSettingsDropdown> {
  late int maxPlayers;
  late int numImpostors;

  @override
  void initState() {
    super.initState();
    maxPlayers = widget.room.maxPlayers;
    numImpostors = widget.room.numImpostors;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
        left: 16.0,
        right: 16.0,
        top: 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            margin: const EdgeInsets.only(bottom: 16.0),
          ),
          // Title
          const Padding(
            padding: EdgeInsets.only(bottom: 24.0),
            child: Text(
              'Configurações da Sala',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Max Players
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Máximo de Jogadores'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$maxPlayers',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: maxPlayers.toDouble(),
                  min: 2,
                  max: 12,
                  divisions: 10,
                  label: '$maxPlayers',
                  onChanged: (value) {
                    setState(() => maxPlayers = value.toInt());
                  },
                  onChangeEnd: (value) async {
                    await _updateMaxPlayers(value.toInt());
                  },
                ),
              ],
            ),
          ),
          // Num Impostors
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Número de Impostores'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$numImpostors',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: numImpostors.toDouble(),
                  min: 1,
                  max: 3,
                  divisions: 2,
                  label: '$numImpostors',
                  onChanged: (value) {
                    setState(() => numImpostors = value.toInt());
                  },
                  onChangeEnd: (value) async {
                    await _updateNumImpostors(value.toInt());
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.close_rounded),
              label: const Text('Fechar'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMaxPlayers(int newValue) async {
    try {
      await widget.gameRepository.updateRoom(widget.room.id, {
        'maxPlayers': newValue,
      });
    } catch (e) {
      if (mounted) {
        GetIt.I<NotificationService>().showError(context, 'Erro ao atualizar');
      }
    }
  }

  Future<void> _updateNumImpostors(int newValue) async {
    try {
      await widget.gameRepository.updateRoom(widget.room.id, {
        'numImpostors': newValue,
      });
    } catch (e) {
      if (mounted) {
        GetIt.I<NotificationService>().showError(context, 'Erro ao atualizar');
      }
    }
  }
}
