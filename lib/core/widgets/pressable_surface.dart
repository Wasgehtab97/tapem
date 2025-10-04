import 'package:flutter/material.dart';

/// Generic pressable surface that provides a consistent scale and overlay
/// feedback based on the profile screen action buttons.
///
/// The [builder] is invoked with the current pressed state so callers can
/// update their decoration (for example by tweaking shadows or borders).
class PressableSurface extends StatefulWidget {
  const PressableSurface({
    super.key,
    required this.builder,
    this.onTap,
    this.borderRadius = BorderRadius.zero,
    this.overlayColor,
    this.showOverlay = true,
    this.pressedScale = 0.985,
    this.duration = const Duration(milliseconds: 160),
    this.curve = Curves.easeOutCubic,
    this.enabled = true,
    this.focusColor,
    this.hoverColor,
  });

  final Widget Function(BuildContext context, bool isPressed) builder;
  final VoidCallback? onTap;
  final BorderRadiusGeometry borderRadius;
  final Color? overlayColor;
  final Color? focusColor;
  final Color? hoverColor;
  final bool showOverlay;
  final double pressedScale;
  final Duration duration;
  final Curve curve;
  final bool enabled;

  @override
  State<PressableSurface> createState() => _PressableSurfaceState();
}

class _PressableSurfaceState extends State<PressableSurface> {
  bool _isPressed = false;

  void _handleHighlight(bool value) {
    if (!mounted || _isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        widget.borderRadius.resolve(Directionality.of(context));
    final overlay = widget.overlayColor ??
        Theme.of(context).colorScheme.onSurface.withOpacity(0.12);

    Widget child = widget.builder(context, widget.enabled && _isPressed);

    if (!widget.enabled || widget.onTap == null) {
      return child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        splashColor: overlay.withOpacity(0.35),
        highlightColor: Colors.transparent,
        focusColor: widget.focusColor ?? overlay.withOpacity(0.25),
        hoverColor: widget.hoverColor ?? overlay.withOpacity(0.18),
        onTap: widget.onTap,
        onHighlightChanged: _handleHighlight,
        child: AnimatedScale(
          scale: _isPressed ? widget.pressedScale : 1,
          duration: widget.duration,
          curve: widget.curve,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              child,
              if (widget.showOverlay)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _isPressed ? 1 : 0,
                      duration: widget.duration,
                      curve: widget.curve,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: borderRadius,
                          color: overlay,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
