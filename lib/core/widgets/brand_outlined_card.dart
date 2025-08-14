import 'package:flutter/material.dart';

import '../theme/app_brand_theme.dart';
import '../theme/design_tokens.dart';

/// Card container with a brand-coloured outline.
class BrandOutlinedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const BrandOutlinedCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).extension<AppBrandTheme>();
    final radius = (surface?.radius ?? BorderRadius.circular(AppRadius.card)) as BorderRadius;
    final borderColor = surface?.outline ?? AppGradients.brandGradient.colors.first;
    final shadow = surface?.shadow;

    Widget content = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: 1),
        boxShadow: shadow,
      ),
      padding: padding ?? const EdgeInsets.all(AppSpacing.sm),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}
