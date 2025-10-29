import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PinInput extends StatefulWidget {
  final int length;
  final Function(String) onComplete;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const PinInput({
    super.key,
    this.length = 6,
    required this.onComplete,
    this.controller,
    this.focusNode,
  });

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _textController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PinCodeTextField(
      appContext: context,
      length: widget.length,
      obscureText: false,
      animationType: AnimationType.fade,
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(12),
        fieldHeight: 60,
        fieldWidth: 52,
        activeFillColor: scheme.surfaceVariant.withOpacity(0.3),
        inactiveFillColor: scheme.surfaceVariant.withOpacity(0.3),
        selectedFillColor: scheme.surfaceVariant.withOpacity(0.5),
        activeColor: scheme.primary,
        inactiveColor: scheme.outline.withOpacity(0.5),
        selectedColor: scheme.primary,
        borderWidth: 1.5,
      ),
      animationDuration: const Duration(milliseconds: 300),
      textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
      backgroundColor: Colors.transparent,
      enableActiveFill: true,
      controller: _textController,
      focusNode: widget.focusNode,
      cursorColor: scheme.primary,
      keyboardType: TextInputType.text,
      boxShadows: const [
        BoxShadow(offset: Offset(0, 1), color: Colors.black12, blurRadius: 10),
      ],
      onCompleted: (value) {
        widget.onComplete(value.toUpperCase());
      },
      onChanged: (value) {},
      beforeTextPaste: (text) {
        return true;
      },
    );
  }
}
