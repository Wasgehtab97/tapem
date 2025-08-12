import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapem/core/theme/brand_surface_theme.dart';

/// Brand aware square button used by the numeric keypad.
class KeyButton extends StatefulWidget {
  /// Icon widget displayed in the centre of the button. Either [icon] or
  /// [label] must be provided.
  final Widget? icon;

  /// Text label displayed in the centre of the button. Either [icon] or
  /// [label] must be provided.
  final String? label;

  /// Callback for a regular tap.
  final VoidCallback? onTap;

  /// Callback when a long press starts. Used for auto‑repeat.
  final GestureLongPressStartCallback? onLongPressStart;

  /// Callback when a long press ends.
  final GestureLongPressEndCallback? onLongPressEnd;

  /// Square dimension of the key.
  final double size;

  /// Semantics label for accessibility.
  final String semanticsLabel;

  /// Whether the key is enabled.
  final bool enabled;

  const KeyButton({
    super.key,
    this.icon,
    this.label,
    required this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
    required this.size,
    required this.semanticsLabel,
    this.enabled = true,
  }) : assert(icon != null || label != null,
            'Either icon or label must be provided');

  @override
  State<KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<KeyButton> {
  bool _pressed = false;
  bool _focused = false;

  void _setPressed(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).extension<BrandSurfaceTheme>();
    final radius = surface?.radius ?? BorderRadius.circular(8);
    final overlay = surface?.pressedOverlay ?? Colors.black26;
    final focusRing = surface?.focusRing ?? Colors.transparent;

    final child = widget.icon ??
        DefaultTextStyle.merge(style: surface?.textStyle, child: Text(widget.label!));

    return Semantics(
      label: widget.semanticsLabel,
      button: true,
      enabled: widget.enabled,
      child: SizedBox.square(
        dimension: math.max(widget.size, 44),
        child: FocusableActionDetector(
          enabled: widget.enabled,
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          child: GestureDetector(
            onTap: widget.enabled
                ? () {
                    HapticFeedback.selectionClick();
                    widget.onTap?.call();
                  }
                : null,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onLongPressStart: widget.enabled
                ? (d) {
                    _setPressed(true);
                    HapticFeedback.selectionClick();
                    widget.onLongPressStart?.call(d);
                  }
                : null,
            onLongPressEnd: widget.enabled
                ? (d) {
                    _setPressed(false);
                    widget.onLongPressEnd?.call(d);
                  }
                : null,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: surface?.gradient,
                borderRadius: radius,
                boxShadow: surface?.shadow,
                border: _focused
                    ? Border.all(color: focusRing, width: 2)
                    : null,
              ),
              child: Stack(
                children: [
                  Center(child: child),
                  if (_pressed)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: overlay,
                          borderRadius: radius,
                        ),
                      ),
                    ),
                  if (!widget.enabled)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .disabledColor
                              .withOpacity(0.4),
                          borderRadius: radius,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


