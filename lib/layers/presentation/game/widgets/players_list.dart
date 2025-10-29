import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:impostor_ar/layers/data/repositories/auth_repository.dart';
import 'package:impostor_ar/layers/data/repositories/game_repository.dart';
import 'package:impostor_ar/layers/domain/models/game_room_model.dart';
import 'package:impostor_ar/layers/presentation/shared/widgets/color_picker_modal.dart';
import 'package:impostor_ar/layers/presentation/game/widgets/player_list_item.dart';

typedef OnKickPlayer =
    void Function(String roomId, String userId, String playerName);

class PlayersList extends StatefulWidget {
  final GameRoom room;
  final GameRepository gameRepository;
  final bool showKickButton;
  final OnKickPlayer? onKickPlayer;

  const PlayersList({
    super.key,
    required this.room,
    required this.gameRepository,
    this.showKickButton = false,
    this.onKickPlayer,
  });

  @override
  State<PlayersList> createState() => _PlayersListState();
}

class _PlayersListState extends State<PlayersList> {
  // Mapa local para rastrear preferência de avatar do usuário atual (session)
  final Map<String, bool> _preferColorMap = {};

  @override
  Widget build(BuildContext context) {
    final currentUser = GetIt.I<AuthRepository>().currentUser;
    final List<Widget> playerWidgets = [];

    // Iterar sobre cada player na lista
    for (final player in widget.room.players) {
      final userId = player.uid;

      // Extrair dados do player
      final playerName = player.name;
      final avatarUrl = player.avatarPhotoUrl;
      final avatarColor = player.avatarColorHex;
      final isPhoto = player.isAvatarPhoto;

      playerWidgets.add(
        PlayerListItem(
          key: ValueKey(userId),
          playerId: userId,
          roomId: widget.room.id,
          playerName: playerName,
          playerPhoto: avatarUrl,
          playerColorHex: avatarColor,
          hasPhoto: isPhoto,
          isHost: userId == widget.room.hostId,
          isCurrentUser: userId == currentUser?.uid,
          showMenu: widget.showKickButton && userId != widget.room.hostId,
          isReady: player.isReady,
          onTap: userId == currentUser?.uid
              ? () => _showColorPicker(context, widget.room, userId)
              : null,
          onKickPlayer: widget.onKickPlayer,
          onBan: widget.showKickButton && userId != widget.room.hostId
              ? () => _showBanConfirmDialog(
                  context,
                  widget.room.id,
                  userId,
                  playerName,
                )
              : null,
        ),
      );
    }

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: SizedBox(child: Column(children: playerWidgets)),
    );
  }

  void _showColorPicker(BuildContext context, GameRoom room, String userId) {
    // Encontrar o player para pegar a foto original
    final player = room.players.firstWhere(
      (p) => p.uid == userId,
      orElse: () => room.players.first,
    );

    // Converter players com cores em mapa de cores (apenas cores, não fotos)
    final playerColorsMap = <String, String>{};
    for (final p in room.players) {
      if (p.isAvatarColor) {
        playerColorsMap[p.uid] = p.avatar;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ColorPickerContent(
        gameRepository: widget.gameRepository,
        roomId: room.id,
        userId: userId,
        currentAvatar: player.avatar,
        userPhotoUrl: player.userPhotoUrl,
        playerColors: playerColorsMap,
        onColorSelected: (colorHex) {
          setState(() {
            _preferColorMap[userId] = true; // Mostrar a cor
          });
        },
        onBackToPhoto: () {
          setState(() {
            _preferColorMap[userId] = false; // Voltar pra foto
          });
        },
      ),
    );
  }

  void _showBanConfirmDialog(
    BuildContext context,
    String roomId,
    String userId,
    String playerName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Banir Jogador?'),
        content: Text('Tem certeza que deseja banir $playerName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await widget.gameRepository.banPlayer(roomId, userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$playerName foi banido da sala!'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao banir jogador: $e'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('Banir'),
          ),
        ],
      ),
    );
  }
}
