import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:impostor_ar/core/services/notification_service.dart';
import 'package:impostor_ar/layers/data/services/qr_code_service.dart';

class ShareRoomSheet extends StatelessWidget {
  final String roomCode;
  final VoidCallback onViewQrPressed;

  const ShareRoomSheet({
    super.key,
    required this.roomCode,
    required this.onViewQrPressed,
  });

  @override
  Widget build(BuildContext context) {
    final roomUrl = QrCodeService.generateRoomUrl(roomCode);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Compartilhar Sala',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _ShareOption(
                    icon: Icons.qr_code_2,
                    label: 'QR Code',
                    onPressed: () {
                      Navigator.pop(context);
                      onViewQrPressed();
                    },
                  ),
                  _ShareOption(
                    icon: Icons.link_rounded,
                    label: 'Copiar Link',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: roomUrl));
                      Navigator.pop(context);
                      GetIt.I<NotificationService>().showSuccess(
                        context,
                        'Link copiado!',
                      );
                    },
                  ),
                  _ShareOption(
                    icon: Icons.share_rounded,
                    label: 'Compartilhar',
                    onPressed: () async {
                      final text =
                          'Entrem na minha sala de Impostor AR!\n\n🎮 Código: $roomCode\n🔗 Link: $roomUrl';
                      try {
                        await Share.share(
                          text,
                          subject: 'Convite para Impostor AR',
                        );
                      } catch (e) {
                        if (context.mounted) {
                          Clipboard.setData(ClipboardData(text: text));
                          GetIt.I<NotificationService>().showSuccess(
                            context,
                            'Mensagem copiada! Cole no seu app favorito.',
                          );
                        }
                      }
                      Navigator.pop(context);
                    },
                  ),
                  _ShareOption(
                    icon: Icons.copy_rounded,
                    label: 'Copiar Código',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: roomCode));
                      Navigator.pop(context);
                      GetIt.I<NotificationService>().showSuccess(
                        context,
                        'Código copiado!',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
