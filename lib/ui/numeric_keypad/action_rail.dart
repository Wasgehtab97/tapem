import 'package:flutter/material.dart';
import 'key_button.dart';

class ActionRail extends StatelessWidget {
  final VoidCallback onHide;
  final VoidCallback onPaste;
  final VoidCallback onCopy;
  final VoidCallback onPlus;
  final VoidCallback onMinus;
  final VoidCallback onClose;
  final double buttonSize;

  const ActionRail({
    super.key,
    required this.onHide,
    required this.onPaste,
    required this.onCopy,
    required this.onPlus,
    required this.onMinus,
    required this.onClose,
    required this.buttonSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        KeyButton(
          size: buttonSize,
          semanticsLabel: 'Tastatur ausblenden',
          onPressed: onHide,
          child: const Icon(Icons.keyboard_hide),
        ),
        KeyButton(
          size: buttonSize,
          semanticsLabel: 'Einfügen',
          onPressed: onPaste,
          child: const Icon(Icons.content_paste),
        ),
        KeyButton(
          size: buttonSize,
          semanticsLabel: 'Kopieren',
          onPressed: onCopy,
          child: const Icon(Icons.copy),
        ),
        KeyButton(
          size: buttonSize,
          semanticsLabel: 'Plus',
          onPressed: onPlus,
          child: const Icon(Icons.add),
        ),
        KeyButton(
          size: buttonSize,
          semanticsLabel: 'Minus',
          onPressed: onMinus,
          child: const Icon(Icons.remove),
        ),
        KeyButton(
          size: buttonSize,
          semanticsLabel: 'Schließen',
          onPressed: onClose,
          child: const Icon(Icons.close),
        ),
      ],
    );
  }
}
