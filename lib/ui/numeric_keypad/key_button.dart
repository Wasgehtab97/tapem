import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapem/core/theme/brand_surface_theme.dart';

class KeyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressEndCallback? onLongPressEnd;
  final double size;
  final String semanticsLabel;

  const KeyButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.onLongPressStart,
    this.onLongPressEnd,
    required this.size,
    required this.semanticsLabel,
  });

  @override
  State<KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<KeyButton> {
  bool _pressed = false;

  void _setPressed(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).extension<BrandSurfaceTheme>();
    final radius = surface?.radius ?? BorderRadius.circular(8);
    final overlay = surface?.pressedOverlay ?? Colors.black26;

    return Semantics(
      label: widget.semanticsLabel,
      button: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onPressed?.call();
            },
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onLongPressStart: (d) {
              _setPressed(true);
              widget.onLongPressStart?.call(d);
            },
            onLongPressEnd: (d) {
              _setPressed(false);
              widget.onLongPressEnd?.call(d);
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: surface?.gradient,
                borderRadius: radius,
                boxShadow: surface?.shadow,
              ),
              child: Stack(
                children: [
                  Center(child: DefaultTextStyle.merge(style: surface?.textStyle, child: widget.child)),
                  if (_pressed)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: overlay,
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

