import 'package:flutter/material.dart';

import '../theme/app_brand_theme.dart';
import 'pressable_surface.dart';

/// Generic container with a branded gradient outline.
///
/// Pulls the outline tokens from [AppBrandTheme] and can be used anywhere a
/// surface with a branded stroke is required.
class BrandOutline extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? radiusOverride;
  final bool isDisabled;
  final bool isSelected;
  final String? semanticLabel;
  final VoidCallback? onTap;

  const BrandOutline({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radiusOverride,
    this.isDisabled = false,
    this.isSelected = false,
    this.semanticLabel,
    this.onTap,
  });

  @override
  State<BrandOutline> createState() => _BrandOutlineState();
}

class _BrandOutlineState extends State<BrandOutline> {
  static const _overlayOpacity = 0.35;
  static const _animationDuration = Duration(milliseconds: 180);

  Widget _buildSurface(
    BuildContext context,
    AppBrandTheme brand,
    BorderRadius radius,
    BorderRadius innerRadius,
    bool highContrast,
    bool isPressed,
  ) {
    final theme = Theme.of(context);
    final overlayColor = brand.pressedOverlay.withOpacity(_overlayOpacity);
    final decoration = BoxDecoration(
      gradient: highContrast ? null : brand.outlineGradient,
      color: highContrast ? brand.outlineColorFallback : null,
      borderRadius: radius,
      boxShadow: widget.isSelected ? brand.outlineShadow : null,
    );

    Widget inner = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: innerRadius,
      ),
      child: Padding(
        padding: widget.padding ?? EdgeInsets.zero,
        child: widget.child,
      ),
    );

    if (widget.onTap != null && !widget.isDisabled) {
      inner = Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          inner,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: isPressed ? 1 : 0,
                duration: _animationDuration,
                curve: Curves.easeOutCubic,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: overlayColor,
                    borderRadius: innerRadius,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      margin: widget.margin,
      decoration: decoration,
      padding: EdgeInsets.all(brand.outlineWidth),
      child: AnimatedContainer(
        duration: _animationDuration,
        curve: Curves.easeOutCubic,
        child: inner,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand =
        Theme.of(context).extension<AppBrandTheme>() ?? AppBrandTheme.defaultTheme();
    final highContrast = MediaQuery.of(context).highContrast;
    final BorderRadius radius =
        (widget.radiusOverride ?? brand.outlineRadius) as BorderRadius;
    final BorderRadius innerRadius =
        radius - BorderRadius.circular(brand.outlineWidth);

    Widget content;
    final isInteractive = widget.onTap != null && !widget.isDisabled;

    if (isInteractive) {
      content = PressableSurface(
        onTap: widget.onTap,
        borderRadius: radius,
        showOverlay: false,
        duration: _animationDuration,
        overlayColor: brand.pressedOverlay.withOpacity(0.2),
        focusColor: brand.focusRing.withOpacity(0.3),
        hoverColor: brand.focusRing.withOpacity(0.16),
        builder: (context, isPressed) => _buildSurface(
          context,
          brand,
          radius,
          innerRadius,
          highContrast,
          isPressed,
        ),
      );
    } else {
      content = _buildSurface(
        context,
        brand,
        radius,
        innerRadius,
        highContrast,
        false,
      );
    }

    if (widget.isDisabled) {
      content = Opacity(
        opacity: brand.outlineDisabledOpacity,
        child: content,
      );
    }

    if (widget.semanticLabel != null || widget.onTap != null) {
      content = Semantics(
        label: widget.semanticLabel,
        button: widget.onTap != null,
        enabled: !widget.isDisabled,
        container: true,
        child: content,
      );
    }

    return content;
  }
}
