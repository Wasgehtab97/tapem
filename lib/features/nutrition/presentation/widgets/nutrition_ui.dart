import 'package:flutter/material.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/widgets/brand_outline_button.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';

class NutritionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const NutritionCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BrandInteractiveCard(
      onTap: onTap,
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      restingBorderColor: theme.colorScheme.outline.withOpacity(0.2),
      activeBorderColor: theme.colorScheme.primary.withOpacity(0.4),
      child: child,
    );
  }
}

class NutritionSectionTitle extends StatelessWidget {
  final String title;
  final Widget? action;

  const NutritionSectionTitle({
    super.key,
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        right: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const MacroPill({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        '$label $value',
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class HeroGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const HeroGradientCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return BrandGradientCard(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );
  }
}

class PrimaryCTA extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const PrimaryCTA({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return BrandPrimaryButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}

class SecondaryCTA extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryCTA({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return BrandOutlineButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
