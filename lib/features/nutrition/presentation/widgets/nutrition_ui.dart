import 'package:flutter/material.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/widgets/brand_outline_button.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

class NutritionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? background;
  final LinearGradient? backgroundGradient;
  final bool neutral;

  const NutritionCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.background,
    this.backgroundGradient,
    this.neutral = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final radius =
        (brand?.radius ?? BorderRadius.circular(AppRadius.cardLg)) as BorderRadius;
    final baseGradient = neutral ? null : (backgroundGradient ?? brand?.gradient);
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;
    final scaffold = theme.scaffoldBackgroundColor;
    final blendedGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(scaffold, brandColor, 0.08) ?? scaffold,
        Color.lerp(scaffold, Colors.black, 0.02) ?? scaffold,
      ],
    );
    final cardPadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        );
    final outlineColor = brand?.outline ?? theme.colorScheme.secondary;
    final borderColor = Colors.white.withOpacity(0.05);

    return BrandInteractiveCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.sm),
      backgroundColor: Colors.transparent,
      borderRadius: radius,
      restingBorderColor: borderColor,
      activeBorderColor: outlineColor.withOpacity(0.25),
      shadowColor: outlineColor.withOpacity(0.15),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: background != null || neutral
              ? null
              : baseGradient != null
                  ? LinearGradient(
                      begin: baseGradient.begin,
                      end: baseGradient.end,
                      colors: baseGradient.colors
                          .map(
                            (c) => Color.lerp(c, scaffold, 0.75) ?? c,
                          )
                          .toList(growable: false),
                    )
                  : blendedGradient,
          color: neutral
              ? scaffold
              : (background ?? scaffold.withOpacity(0.92)),
          borderRadius: radius,
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: cardPadding,
          child: child,
        ),
      ),
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

class NutritionActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const NutritionActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;
    final radius = BorderRadius.circular(AppRadius.cardLg);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  brandColor.withOpacity(0.08),
                  brandColor.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.onSurface,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        brandColor.withOpacity(0.22),
                        brandColor.withOpacity(0.02),
                      ],
                      center: Alignment.topLeft,
                      radius: 1.0,
                    ),
                    border: Border.all(
                      color: brandColor.withOpacity(0.4),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    color: brandColor,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const MacroPill({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        '$label $value',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
    if (onTap == null) return pill;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.chip),
      onTap: onTap,
      child: pill,
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
    final theme = Theme.of(context);
    return NutritionCard(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: (theme.extension<AppBrandTheme>()?.gradient ??
                AppGradients.brandGradient)
            .colors
            .map(
              (c) => Color.lerp(c, theme.scaffoldBackgroundColor, 0.45) ?? c,
            )
            .toList(growable: false),
      ),
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
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;
    final scaffold = theme.scaffoldBackgroundColor;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(scaffold, brandColor, 0.08) ?? scaffold,
        Color.lerp(scaffold, Colors.black, 0.02) ?? scaffold,
      ],
    );
    final iconBg = brandColor.withOpacity(0.12);
    final fg = theme.colorScheme.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.cardLg),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(icon, size: 18, color: fg),
                  ),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.arrow_outward_rounded, size: 18, color: brandColor),
              ],
            ),
          ),
        ),
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
