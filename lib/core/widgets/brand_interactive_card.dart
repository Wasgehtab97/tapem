import 'package:flutter/material.dart';

import '../logging/elog.dart';
import '../theme/app_brand_theme.dart';
import '../theme/design_tokens.dart';

/// Animated surface matching the outline style used on the profile actions.
class BrandInteractiveCard extends StatefulWidget {
  const BrandInteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    this.margin,
    this.backgroundColor,
    this.restingBorderColor,
    this.activeBorderColor,
    this.shadowColor,
    this.borderRadius,
    this.showShadow = true,
    this.showPressedOverlay = true,
    this.enableScaleAnimation = true,
    this.semanticLabel,
    this.uiLogEvent,
  });

  /// Content rendered inside the card.
  final Widget child;

  /// Callback executed when the card is tapped.
  final VoidCallback? onTap;

  /// Padding applied to [child].
  final EdgeInsetsGeometry padding;

  /// Optional outer margin for the card.
  final EdgeInsetsGeometry? margin;

  /// Background color of the card. Defaults to the scaffold background colour.
  final Color? backgroundColor;

  /// Border color when the card is idle.
  final Color? restingBorderColor;

  /// Border color when the card is pressed.
  final Color? activeBorderColor;

  /// Shadow tint for the card.
  final Color? shadowColor;

  /// Corner radius applied to the card.
  final BorderRadiusGeometry? borderRadius;

  /// Whether a drop shadow should be drawn.
  final bool showShadow;

  /// Whether a pressed overlay is drawn when the card is held down.
  final bool showPressedOverlay;

  /// Whether the scale animation is played on press.
  final bool enableScaleAnimation;

  /// Optional semantic label announced to assistive technologies.
  final String? semanticLabel;

  /// Event name for UI telemetry.
  final String? uiLogEvent;

  @override
  State<BrandInteractiveCard> createState() => _BrandInteractiveCardState();
}

class _BrandInteractiveCardState extends State<BrandInteractiveCard> {
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    if (widget.uiLogEvent != null) {
      elogUi(widget.uiLogEvent!, {'label': widget.semanticLabel});
    }
  }

  @override
  void didUpdateWidget(covariant BrandInteractiveCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uiLogEvent != oldWidget.uiLogEvent && widget.uiLogEvent != null) {
      elogUi(widget.uiLogEvent!, {'label': widget.semanticLabel});
    }
  }

  void _handleHighlight(bool value) {
    if (_isPressed == value || !mounted) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final radius = (widget.borderRadius ??
            brandTheme?.radius ??
            BorderRadius.circular(AppRadius.card))
        as BorderRadius;
    final onSurface = theme.colorScheme.onSurface;
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final overlay = brandTheme?.pressedOverlay ?? onSurface.withOpacity(0.08);
    final backgroundColor =
        widget.backgroundColor ?? theme.scaffoldBackgroundColor;
    final restingBorder =
        widget.restingBorderColor ?? onSurface.withOpacity(0.12);
    final activeBorder =
        widget.activeBorderColor ?? brandColor.withOpacity(0.45);
    final borderColor =
        Color.lerp(restingBorder, activeBorder, _isPressed ? 1 : 0)!;
    final canTap = widget.onTap != null;
    final shadowBase =
        (widget.shadowColor ?? theme.shadowColor).withOpacity(_isPressed ? 0.08 : 0.16);

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: Border.all(color: borderColor),
        boxShadow: widget.showShadow
            ? [
                BoxShadow(
                  color: shadowBase,
                  blurRadius: _isPressed ? 10 : 20,
                  offset: Offset(0, _isPressed ? 6 : 14),
                ),
              ]
            : const [],
      ),
      child: Stack(
        children: [
          if (widget.showPressedOverlay)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _isPressed ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: overlay.withOpacity(0.35),
                    borderRadius: radius,
                  ),
                ),
              ),
            ),
          Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ],
      ),
    );

    final animated = widget.enableScaleAnimation
        ? AnimatedScale(
            scale: _isPressed ? 0.985 : 1,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: card,
          )
        : card;

    final ink = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        splashColor: canTap ? overlay.withOpacity(0.3) : Colors.transparent,
        highlightColor: Colors.transparent,
        onHighlightChanged: canTap ? _handleHighlight : null,
        onTap: widget.onTap,
        child: animated,
      ),
    );

    final semantics = Semantics(
      button: canTap,
      enabled: canTap,
      label: widget.semanticLabel,
      child: ink,
    );

    return Container(
      margin: widget.margin,
      child: semantics,
    );
  }
}
