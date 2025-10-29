import 'package:flutter/material.dart';

class ButtonsHeader extends StatelessWidget {
  final List<Widget> buttons;
  final double spacing;
  final double rightPadding;

  const ButtonsHeader({
    super.key,
    required this.buttons,
    this.spacing = 4,
    this.rightPadding = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: rightPadding),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            buttons[i],
            if (i < buttons.length - 1) SizedBox(width: spacing),
          ],
        ],
      ),
    );
  }
}
