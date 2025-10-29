import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:impostor_ar/layers/domain/models/game_room_model.dart';
import 'package:impostor_ar/layers/domain/models/player_model.dart';

class GameStartScreen extends StatefulWidget {
  final GameRoom room;
  final String currentUserId;

  const GameStartScreen({
    Key? key,
    required this.room,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<GameStartScreen> createState() => _GameStartScreenState();
}

class _GameStartScreenState extends State<GameStartScreen> {
  late bool _isCurrentUserImpostor;
  late List<Player> _visiblePlayers;

  @override
  void initState() {
    super.initState();
    _isCurrentUserImpostor = widget.room.impostorIds.contains(
      widget.currentUserId,
    );
    _prepareVisiblePlayers();
  }

  void _prepareVisiblePlayers() {
    if (_isCurrentUserImpostor) {
      // Impostores veem todos os outros impostores
      _visiblePlayers = widget.room.players
          .where((p) => p.uid != widget.currentUserId)
          .toList();
    } else {
      // Crewmates veem apenas outros crewmates (não impostores)
      _visiblePlayers = widget.room.players
          .where(
            (p) =>
                p.uid != widget.currentUserId &&
                !widget.room.impostorIds.contains(p.uid),
          )
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = widget.room.players.firstWhere(
      (p) => p.uid == widget.currentUserId,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Seção do usuário atual (maior)
            Container(
              padding: const EdgeInsets.all(24),
              color: _isCurrentUserImpostor
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Você é...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Avatar grande
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isCurrentUserImpostor
                            ? Colors.red
                            : Colors.green,
                        width: 4,
                      ),
                    ),
                    child: _buildPlayerAvatar(currentPlayer),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isCurrentUserImpostor ? 'IMPOSTOR' : 'CREWMATE',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _isCurrentUserImpostor ? Colors.red : Colors.green,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentPlayer.name,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            // Seção de outros jogadores
            if (_visiblePlayers.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Colors.grey.shade900,
                width: double.infinity,
                child: Text(
                  _isCurrentUserImpostor
                      ? 'SEUS CÚMPLICES:'
                      : 'SEUS COMPANHEIROS:',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _visiblePlayers.length,
                itemBuilder: (context, index) {
                  final player = _visiblePlayers[index];
                  return Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30, width: 2),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: _buildPlayerAvatar(player),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ] else
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _isCurrentUserImpostor
                      ? 'Você é o único impostor!'
                      : 'Você está sozinho!',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
            // Seção de espera
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'O jogo vai começar em breve...',
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerAvatar(Player player) {
    final playerColor = Color(
      int.parse('FF${player.avatarColorHex}', radix: 16),
    );
    final showPhotoAvatar = player.isAvatarPhoto;

    return ClipOval(
      child: Container(
        color: !showPhotoAvatar ? playerColor : Colors.grey.shade100,
        child: showPhotoAvatar && player.avatarPhotoUrl != null
            ? CachedNetworkImage(
                imageUrl: player.avatarPhotoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(playerColor),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.grey.shade600,
                    size: 40,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
