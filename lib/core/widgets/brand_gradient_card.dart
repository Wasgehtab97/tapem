import 'package:flutter/material.dart';
import '../theme/app_brand_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/brand_on_colors.dart';

/// Reusable card container with the brand gradient and rounded corners.
class BrandGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;

  const BrandGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.extension<AppBrandTheme>();
    final BorderRadius radius =
        (borderRadius ?? surface?.radius ?? BorderRadius.circular(AppRadius.card))
            as BorderRadius;
    final gradient = surface?.gradient ?? AppGradients.brandGradient;
    final shadow = surface?.shadow;
    final overlay = surface?.pressedOverlay ?? Colors.black26;
    final onBrand =
        Theme.of(context).extension<BrandOnColors>()?.onGradient ??
            Colors.black;

    Widget content = Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: radius,
        boxShadow: shadow,
      ),
      padding: padding ?? const EdgeInsets.all(AppSpacing.sm),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: onBrand),
        child: IconTheme(
          data: IconThemeData(color: onBrand),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          splashColor: overlay,
          highlightColor: overlay,
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Gradient header used for expansion tiles.
class BrandGradientHeader extends StatelessWidget {
  final Widget child;
  final bool expanded;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const BrandGradientHeader({
    super.key,
    required this.child,
    this.expanded = false,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).extension<AppBrandTheme>();
    final baseRadius = surface?.radius as BorderRadius? ?? BorderRadius.circular(AppRadius.card);
    final radius = expanded
        ? BorderRadius.only(topLeft: baseRadius.topLeft, topRight: baseRadius.topRight)
        : baseRadius;
    return BrandGradientCard(
      borderRadius: radius,
      padding: padding ?? const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
      onTap: onTap,
      child: child,
    );
  }
}
