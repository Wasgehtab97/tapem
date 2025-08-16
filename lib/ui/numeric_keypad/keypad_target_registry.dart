// lib/ui/numeric_keypad/keypad_target_registry.dart
// Lightweight registry for numeric keypad routing targets.

import 'dart:ui';
import 'package:flutter/widgets.dart';

/// Type of target handled by the keypad router.
enum KeypadTargetType { numeric, plus, text }

/// Target information used for routing taps from the keypad barrier.
class KeypadTarget {
  KeypadTarget({
    required this.id,
    required this.type,
    required this.getRect,
    this.focusNode,
    this.controller,
    this.allowDecimal = true,
    this.integerStep,
    this.decimalStep,
    this.onCommand,
  });

  final String id;
  final KeypadTargetType type;
  final Rect Function() getRect;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final bool allowDecimal;
  final double? integerStep;
  final double? decimalStep;
  final VoidCallback? onCommand;
}

/// Global registry singleton.
class KeypadTargetRegistry extends ChangeNotifier {
  KeypadTargetRegistry._();

  static final instance = KeypadTargetRegistry._();

  final List<KeypadTarget> _targets = [];

  List<KeypadTarget> get targets => List.unmodifiable(_targets);

  void register(KeypadTarget target) {
    _targets.add(target);
    notifyListeners();
  }

  void unregister(KeypadTarget target) {
    _targets.remove(target);
    notifyListeners();
  }
}

/// Utility to compute a global rect from a [GlobalKey].
Rect globalRectFromKey(GlobalKey key) {
  final ctx = key.currentContext;
  if (ctx == null) return Rect.zero;
  final box = ctx.findRenderObject() as RenderBox?;
  if (box == null) return Rect.zero;
  final offset = box.localToGlobal(Offset.zero);
  return offset & box.size;
}

