import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:impostor_ar/layers/data/services/qr_code_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  late MobileScannerController _controller;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture barcodes) {
    if (_hasScanned) return;

    for (final barcode in barcodes.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _hasScanned = true;

        final roomCode = QrCodeService.extractRoomCodeFromUrl(code) ?? code;
        context.go('/home/join', extra: {'roomCode': roomCode});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR Code'), centerTitle: true),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Column(
              children: [
                Expanded(flex: 2, child: Container()),
                Expanded(
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.greenAccent, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      width: 250,
                      height: 250,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Aponte para um QR Code',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'com o código da sala',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
