import 'package:flutter/material.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';

class HeroGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const HeroGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final gradient = brand?.gradient ?? AppGradients.brandGradient;

    return BrandInteractiveCard(
      onTap: onTap,
      padding: EdgeInsets.zero, // Padding handled by internal container
      enableScaleAnimation: onTap != null,
      borderColor: null, // Clean up erroneous parameter
      restingBorderColor: gradient.colors.first.withOpacity(0.3),
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradient.colors.first.withOpacity(0.15),
              gradient.colors.last.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.cardLg),
        ),
        child: child,
      ),
    );
  }
}
