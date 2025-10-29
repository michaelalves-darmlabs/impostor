import 'package:flutter/material.dart';

class QrCodeDisplay extends StatelessWidget {
  final String data;
  final double size;
  final String? label;

  const QrCodeDisplay({
    super.key,
    required this.data,
    this.size = 250,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: Image.network(
              'https://api.qrserver.com/v1/create-qr-code/?size=${size.toInt()}x${size.toInt()}&data=${Uri.encodeComponent(data)}',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}
