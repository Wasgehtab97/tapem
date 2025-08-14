import 'package:flutter/material.dart';

import '../theme/app_brand_theme.dart';

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
  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrandTheme>()!;
    final highContrast = MediaQuery.of(context).highContrast;
    final BorderRadius radius =
        (widget.radiusOverride ?? brand.outlineRadius) as BorderRadius;
    final BorderRadius innerRadius =
        radius - BorderRadius.circular(brand.outlineWidth);
    final decoration = BoxDecoration(
      gradient: highContrast ? null : brand.outlineGradient,
      color: highContrast ? brand.outlineColorFallback : null,
      borderRadius: radius,
      boxShadow: widget.isSelected ? brand.outlineShadow : null,
    );

    Widget content = Container(
      margin: widget.margin,
      decoration: decoration,
      padding: EdgeInsets.all(brand.outlineWidth),
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: innerRadius,
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: innerRadius,
          onTap: widget.isDisabled ? null : widget.onTap,
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return brand.pressedOverlay;
            }
            if (states.contains(MaterialState.focused)) {
              return brand.focusRing.withOpacity(0.3);
            }
            return null;
          }),
          child: content,
        ),
      );
    }

    if (widget.isDisabled) {
      content = Opacity(
        opacity: brand.outlineDisabledOpacity,
        child: content,
      );
    }

    if (widget.semanticLabel != null) {
      content = Semantics(
        label: widget.semanticLabel,
        container: true,
        child: content,
      );
    }

    return content;
  }
}
