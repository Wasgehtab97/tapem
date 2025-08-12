import 'package:flutter/material.dart';

import 'key_button.dart';

/// Vertical rail with action keys used by the numeric keypad.
class ActionRail extends StatelessWidget {
  final VoidCallback onHide;
  final VoidCallback onPaste;
  final VoidCallback onCopy;
  final VoidCallback onPlus;
  final VoidCallback onMinus;
  final VoidCallback onClose;
  final GestureLongPressStartCallback? onPlusLongPressStart;
  final GestureLongPressEndCallback? onPlusLongPressEnd;
  final GestureLongPressStartCallback? onMinusLongPressStart;
  final GestureLongPressEndCallback? onMinusLongPressEnd;
  final double keySize;
  final bool canPaste;
  final bool canCopy;
  final bool canPlus;
  final bool canMinus;

  const ActionRail({
    super.key,
    required this.onHide,
    required this.onPaste,
    required this.onCopy,
    required this.onPlus,
    required this.onMinus,
    required this.onClose,
    required this.keySize,
    this.onPlusLongPressStart,
    this.onPlusLongPressEnd,
    this.onMinusLongPressStart,
    this.onMinusLongPressEnd,
    this.canPaste = true,
    this.canCopy = true,
    this.canPlus = true,
    this.canMinus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        KeyButton(
          icon: const Icon(Icons.keyboard_hide),
          semanticsLabel: 'Tastatur ausblenden',
          onTap: onHide,
          size: keySize,
        ),
        KeyButton(
          icon: const Icon(Icons.content_paste),
          semanticsLabel: 'Einfügen',
          onTap: canPaste ? onPaste : null,
          size: keySize,
          enabled: canPaste,
        ),
        KeyButton(
          icon: const Icon(Icons.copy),
          semanticsLabel: 'Kopieren',
          onTap: canCopy ? onCopy : null,
          size: keySize,
          enabled: canCopy,
        ),
        KeyButton(
          icon: const Icon(Icons.add),
          semanticsLabel: 'Plus',
          onTap: canPlus ? onPlus : null,
          onLongPressStart: canPlus ? onPlusLongPressStart : null,
          onLongPressEnd: canPlus ? onPlusLongPressEnd : null,
          size: keySize,
          enabled: canPlus,
        ),
        KeyButton(
          icon: const Icon(Icons.remove),
          semanticsLabel: 'Minus',
          onTap: canMinus ? onMinus : null,
          onLongPressStart: canMinus ? onMinusLongPressStart : null,
          onLongPressEnd: canMinus ? onMinusLongPressEnd : null,
          size: keySize,
          enabled: canMinus,
        ),
        KeyButton(
          icon: const Icon(Icons.close),
          semanticsLabel: 'Schließen',
          onTap: onClose,
          size: keySize,
        ),
      ],
    );
  }
}
