import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:impostor_ar/core/services/notification_service.dart';
import 'package:impostor_ar/layers/presentation/shared/widgets/room_code_badge.dart';
import 'package:impostor_ar/layers/presentation/shared/widgets/buttons_header.dart';

typedef OnSharePressed = void Function();
typedef OnSettingsPressed = void Function();

class RoomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String roomCode;
  final VoidCallback onBackPressed;
  final OnSharePressed onShare;
  final OnSettingsPressed? onSettings;
  final bool showSettings;

  const RoomAppBar({
    super.key,
    required this.roomCode,
    required this.onBackPressed,
    required this.onShare,
    this.onSettings,
    this.showSettings = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: onBackPressed,
      ),
      title: RoomCodeBadge(
        code: roomCode,
        onCopyPressed: () {
          Clipboard.setData(ClipboardData(text: roomCode));
          GetIt.I<NotificationService>().showSuccess(
            context,
            'Código copiado!',
          );
        },
      ),
      centerTitle: true,
      actions: [
        ButtonsHeader(
          buttons: [
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: onShare,
              tooltip: 'Compartilhar',
            ),
            if (showSettings)
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                onPressed: onSettings!,
                tooltip: 'Configurações',
              ),
          ],
        ),
      ],
    );
  }
}
