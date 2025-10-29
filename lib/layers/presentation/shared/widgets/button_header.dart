import 'package:flutter/material.dart';

class ButtonHeader extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double rightPadding;

  const ButtonHeader({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.rightPadding = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: rightPadding),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}
