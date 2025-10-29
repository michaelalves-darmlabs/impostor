import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

typedef OnKickPlayer =
    void Function(String roomId, String userId, String playerName);

class PlayerListItem extends StatelessWidget {
  final String playerId;
  final String roomId;
  final String playerName;
  final String? playerPhoto;
  final String playerColorHex;
  final bool hasPhoto;
  final bool isHost;
  final bool isCurrentUser;
  final bool showMenu;
  final bool isReady;
  final VoidCallback? onTap;
  final OnKickPlayer? onKickPlayer;
  final VoidCallback? onBan;

  const PlayerListItem({
    required Key key,
    required this.playerId,
    required this.roomId,
    required this.playerName,
    required this.playerPhoto,
    required this.playerColorHex,
    required this.hasPhoto,
    required this.isHost,
    required this.isCurrentUser,
    required this.showMenu,
    required this.isReady,
    this.onTap,
    this.onKickPlayer,
    this.onBan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerColor = Color(int.parse('FF$playerColorHex', radix: 16));
    final showPhotoAvatar = hasPhoto;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 8, right: 4, top: 12, bottom: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    color: !showPhotoAvatar
                        ? playerColor
                        : Colors.grey.shade100,
                  ),
                  child: showPhotoAvatar
                      ? _AvatarImage(
                          photoUrl: playerPhoto!,
                          fallbackColor: playerColor,
                        )
                      : null,
                ),
                if (isHost)
                  Positioned(
                    top: -8,
                    left: 0,
                    child: Transform.rotate(
                      angle: -0.4363,
                      child: const FaIcon(
                        FontAwesomeIcons.crown,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                  ),
                if (isCurrentUser)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Nome e role
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          playerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          isHost ? 'Anfitrião' : 'Jogador',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isReady)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Pronto',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Menu de ações
            if (showMenu && !isHost)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                offset: const Offset(0, 40),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'kick') {
                    onKickPlayer?.call(roomId, playerId, playerName);
                  } else if (value == 'ban') {
                    onBan?.call();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'kick',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, size: 20),
                        SizedBox(width: 12),
                        Text('Remover'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'ban',
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 20),
                        SizedBox(width: 12),
                        Text('Banir'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  final String photoUrl;
  final Color fallbackColor;

  const _AvatarImage({required this.photoUrl, required this.fallbackColor});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          alignment: Alignment.center,
          color: fallbackColor,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          alignment: Alignment.center,
          color: Colors.grey.shade600,
          child: const Icon(Icons.person, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
