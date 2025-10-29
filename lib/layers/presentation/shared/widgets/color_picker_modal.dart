import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:impostor_ar/core/models/player_color.dart';
import 'package:impostor_ar/layers/data/repositories/game_repository.dart';
import 'package:impostor_ar/layers/domain/models/game_room_model.dart';

typedef OnColorSelected = void Function(String colorHex);
typedef OnBackToPhoto = void Function();

class ColorPickerContent extends StatefulWidget {
  final GameRepository gameRepository;
  final String roomId;
  final String userId;
  final String? userPhotoUrl; // Foto original do usuário
  final String currentAvatar; // Avatar atual (cor ou foto URL)
  final Map<String, String> playerColors;
  final OnColorSelected? onColorSelected;
  final OnBackToPhoto? onBackToPhoto;

  const ColorPickerContent({
    required this.gameRepository,
    required this.roomId,
    required this.userId,
    required this.currentAvatar,
    required this.playerColors,
    this.userPhotoUrl,
    this.onColorSelected,
    this.onBackToPhoto,
  });

  @override
  State<ColorPickerContent> createState() => _ColorPickerContentState();
}

class _ColorPickerContentState extends State<ColorPickerContent> {
  late final Stream<GameRoom?> _roomStream;

  @override
  void initState() {
    super.initState();
    // Criar stream apenas uma vez
    _roomStream = widget.gameRepository.getRoomStream(widget.roomId);
  }

  @override
  Widget build(BuildContext context) {
    // Usar StreamBuilder com o stream de initState
    return StreamBuilder<GameRoom?>(
      stream: _roomStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final room = snapshot.data!;

        // Reconstruir mapa de cores dos outros players
        final playerColorsMap = <String, String>{};
        for (final player in room.players) {
          if (player.isAvatarColor) {
            playerColorsMap[player.uid] = player.avatar;
          }
        }

        final usedColors = playerColorsMap.values.toSet();

        // Usar o avatar atual passado como parâmetro (pode ser foto URL ou cor hex)
        // Se for foto, extrair a cor padrão; se for cor, usar ela mesma
        final currentAvatarIsColor = RegExp(
          r'^[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$',
        ).hasMatch(widget.currentAvatar.replaceFirst('#', ''));
        final currentColor = currentAvatarIsColor
            ? widget.currentAvatar
            : 'PHOTO'; // Usar 'PHOTO' como identificador da foto

        final List<Widget> colorWidgets = [];

        // Adicionar foto como primeira opção (se existir)
        if (widget.userPhotoUrl != null && widget.userPhotoUrl!.isNotEmpty) {
          colorWidgets.add(
            _PhotoListItem(
              key: const ValueKey('PHOTO'),
              photoUrl: widget.userPhotoUrl!,
              isSelected: currentColor == 'PHOTO',
              gameRepository: widget.gameRepository,
              roomId: widget.roomId,
              userId: widget.userId,
              onPhotoSelected: widget.onBackToPhoto,
            ),
          );
        }

        // Adicionar cores
        for (int index = 0; index < PlayerColor.values.length; index++) {
          final color = PlayerColor.values[index];
          final isUsed =
              usedColors.contains(color.hex) && currentColor != color.hex;
          final isSelected = currentColor == color.hex;

          colorWidgets.add(
            _ColorListItem(
              key: ValueKey(color.hex),
              color: color,
              isUsed: isUsed,
              isSelected: isSelected,
              gameRepository: widget.gameRepository,
              roomId: widget.roomId,
              userId: widget.userId,
              onColorSelected: widget.onColorSelected,
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Escolher Avatar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(children: colorWidgets),
                ),
              ),
              const SizedBox(height: 16),
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
      },
    );
  }
}

class _ColorListItem extends StatelessWidget {
  final PlayerColor color;
  final bool isUsed;
  final bool isSelected;
  final GameRepository gameRepository;
  final String roomId;
  final String userId;
  final OnColorSelected? onColorSelected;

  const _ColorListItem({
    required Key key,
    required this.color,
    required this.isUsed,
    required this.isSelected,
    required this.gameRepository,
    required this.roomId,
    required this.userId,
    required this.onColorSelected,
  }) : super(key: key);

  void _handleColorTap(BuildContext context) async {
    // Fechar o modal ANTES de fazer a atualização
    Navigator.pop(context);

    // Depois atualizar a cor de forma assíncrona
    try {
      final success = await gameRepository.updatePlayerColor(
        roomId,
        userId,
        color.hex,
      );

      if (success) {
        onColorSelected?.call(color.hex);
      } else {
        // Mostrar notificação de erro - cor já está em uso
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Esta cor já está em uso por outro jogador!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Erro silencioso já que modal foi fechado
      print('Erro ao atualizar cor: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Envolver em RepaintBoundary para evitar problemas de diagnostics em Web
    return RepaintBoundary(
      child: AbsorbPointer(
        absorbing: isUsed,
        child: Opacity(
          opacity: isUsed ? 0.5 : 1.0,
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(int.parse('FF${color.hex}', radix: 16)),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : Border.all(color: Colors.grey, width: 1),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, color: Colors.white, size: 20),
                    )
                  : null,
            ),
            title: Text(color.displayName),
            trailing: isUsed ? const Icon(Icons.lock, size: 18) : null,
            onTap: isUsed ? null : () => _handleColorTap(context),
          ),
        ),
      ),
    );
  }
}

class _PhotoListItem extends StatelessWidget {
  final String photoUrl;
  final bool isSelected;
  final GameRepository gameRepository;
  final String roomId;
  final String userId;
  final VoidCallback? onPhotoSelected;

  const _PhotoListItem({
    required Key key,
    required this.photoUrl,
    required this.isSelected,
    required this.gameRepository,
    required this.roomId,
    required this.userId,
    required this.onPhotoSelected,
  }) : super(key: key);

  void _handlePhotoTap(BuildContext context) async {
    // Fechar o modal ANTES de fazer a atualização
    Navigator.pop(context);

    // Depois atualizar o avatar para a foto original
    try {
      await gameRepository.updatePlayerColor(roomId, userId, photoUrl);
      onPhotoSelected?.call();
    } catch (e) {
      print('Erro ao selecionar foto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListTile(
        leading: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : Border.all(color: Colors.grey, width: 1),
              ),
              child: ClipOval(
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey,
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
            ),
            if (isSelected)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
        title: const Text('Minha Foto'),
        onTap: () => _handlePhotoTap(context),
      ),
    );
  }
}
