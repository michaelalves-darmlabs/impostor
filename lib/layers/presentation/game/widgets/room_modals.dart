import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:impostor_ar/core/constants.dart';
import 'package:impostor_ar/core/services/notification_service.dart';
import 'package:share_plus/share_plus.dart';

class RoomModals {
  static void showShareMenu(
    BuildContext context,
    String roomCode,
    VoidCallback onQrCode,
  ) {
    final roomUrl = '${AppConstants.baseUrl}/$roomCode';

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Compartilhar Sala',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_rounded),
              title: const Text('QR Code'),
              onTap: () {
                Navigator.pop(context);
                onQrCode();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded),
              title: const Text('Copiar Link'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: roomUrl));
                Navigator.pop(context);
                GetIt.I<NotificationService>().showSuccess(
                  context,
                  'Link copiado!',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copiar Código'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: roomCode));
                Navigator.pop(context);
                GetIt.I<NotificationService>().showSuccess(
                  context,
                  'Código copiado!',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Compartilhar'),
              onTap: () {
                Navigator.pop(context);
                _shareRoom(context, roomCode);
              },
            ),
          ],
        ),
      ),
    );
  }

  static void showQrCode(BuildContext context, String roomCode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'QR Code da Sala',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.network(
                '${AppConstants.qrCodeApiUrl}/?size=280x280&data=${Uri.encodeComponent('${AppConstants.baseUrl}/$roomCode')}',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              roomCode,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppConstants.baseUrl}/$roomCode',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _shareRoom(BuildContext context, String roomCode) async {
    final link = '${AppConstants.baseUrl}/$roomCode';
    try {
      await Share.share(
        'Venha jogar Impostor AR comigo!\n\nCódigo: $roomCode\nLink: $link',
        subject: 'Convite para Impostor AR',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao compartilhar: $e')));
      }
    }
  }
}
