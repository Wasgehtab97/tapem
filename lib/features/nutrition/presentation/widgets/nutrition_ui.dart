import 'package:flutter/material.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/widgets/brand_outline_button.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/core/widgets/premium_action_tile.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

Color nutritionBrandAccentColor(BuildContext context) {
  final theme = Theme.of(context);
  final brand = theme.extension<AppBrandTheme>();
  return brand?.outline ?? theme.colorScheme.secondary;
}

/// Premium nutrition card with brand interactive styling
class NutritionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? background;
  final LinearGradient? backgroundGradient;
  final bool neutral;
  final bool enableGlow;

  const NutritionCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.background,
    this.backgroundGradient,
    this.neutral = false,
    this.enableGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;

    return BrandInteractiveCard(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.sm),
      backgroundColor: background ?? theme.scaffoldBackgroundColor,
      borderRadius: brand?.outlineRadius ?? BorderRadius.circular(AppRadius.cardLg),
      showShadow: enableGlow,
      shadowColor: brandColor.withOpacity(0.08),
      enableScaleAnimation: onTap != null,
      child: child,
    );
  }
}

/// Section title with optional action
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
            child: BrandGradientText(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Premium action tile matching ProfileScreen design
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
    return PremiumActionTile(
      leading: Icon(icon, size: 20),
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      accentColor: brandColor,
    );
  }
}

/// Macro pill with brand gradient styling
class MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final bool enableGlow;

  const MacroPill({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
    this.enableGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = nutritionBrandAccentColor(context);

    final pill = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                fontSize: 11,
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return pill;

    return GestureDetector(
      onTap: onTap,
      child: pill,
    );
  }
}

/// Hero gradient card with compact premium surface styling.
class HeroGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool enableBackdropBlur;

  const HeroGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.enableBackdropBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final gradient = brand?.gradient ?? AppGradients.brandGradient;
    final radius = brand?.outlineRadius ?? BorderRadius.circular(AppRadius.cardLg);

    final softenedGradient = LinearGradient(
      begin: gradient.begin,
      end: gradient.end,
      colors: gradient.colors
          .map(
            (c) => Color.lerp(c, theme.scaffoldBackgroundColor, 0.9) ?? c,
          )
          .toList(growable: false),
    );

    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: softenedGradient,
        borderRadius: radius,
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
          width: 0.8,
        ),
      ),
      child: child,
    );
  }
}

/// Primary CTA matching workout screen save button
class PrimaryCTA extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const PrimaryCTA({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;
    final enabled = onPressed != null && !isLoading;

    final gradient = enabled
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: (brand?.gradient ?? AppGradients.brandGradient).colors.map((c) {
              return Color.lerp(c, theme.scaffoldBackgroundColor, 0.55) ?? c;
            }).toList(),
          )
        : null;

    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: gradient,
        color: enabled ? null : Colors.white.withOpacity(0.04),
        border: Border.all(
          color: enabled
              ? brandColor.withOpacity(0.28)
              : theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon!, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: enabled ? Colors.white : Colors.white.withOpacity(0.3),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.2,
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

/// Secondary CTA using brand outline button
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
            BrandGradientIcon(icon!, size: 18),
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

/// Animated stat widget with optional flicker effect
class AnimatedNutritionStat extends StatefulWidget {
  final int value;
  final String label;
  final Color? color;
  final bool enableFlicker;

  const AnimatedNutritionStat({
    super.key,
    required this.value,
    required this.label,
    this.color,
    this.enableFlicker = false,
  });

  @override
  State<AnimatedNutritionStat> createState() => _AnimatedNutritionStatState();
}

class _AnimatedNutritionStatState extends State<AnimatedNutritionStat>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int? _previousValue;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.enableFlicker) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedNutritionStat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
    }
    if (widget.enableFlicker != oldWidget.enableFlicker) {
      if (widget.enableFlicker) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final color = widget.color ?? brand?.outline ?? theme.colorScheme.secondary;

    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: _previousValue ?? widget.value, end: widget.value),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final flickerIntensity = widget.enableFlicker ? 0.18 : 0.0;
        final t = 1.0 - flickerIntensity + _controller.value * 2 * flickerIntensity;
        final animatedColor = Color.lerp(color.withOpacity(0.7), color, t) ?? color;

        return Column(
          children: [
            Text(
              value.toString(),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: animatedColor,
                fontWeight: FontWeight.bold,
                fontSize: 32,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              widget.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<String?> showMealSelectionDialog(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Mahlzeit wählen',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny_outlined, size: 24),
            title: const Text('Frühstück'),
            onTap: () => Navigator.pop(context, 'breakfast'),
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny_rounded, size: 24),
            title: const Text('Mittagessen'),
            onTap: () => Navigator.pop(context, 'lunch'),
          ),
          ListTile(
            leading: const Icon(Icons.nights_stay_outlined, size: 24),
            title: const Text('Abendessen'),
            onTap: () => Navigator.pop(context, 'dinner'),
          ),
          ListTile(
            leading: const Icon(Icons.cookie_outlined, size: 24),
            title: const Text('Snack'),
            onTap: () => Navigator.pop(context, 'snack'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
}

class NutritionMealPicker extends StatelessWidget {
  final String selectedMeal;
  final ValueChanged<String> onChanged;

  const NutritionMealPicker({
    super.key,
    required this.selectedMeal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meals = [
      ('breakfast', 'Frühstück', Icons.wb_twilight_rounded),
      ('lunch', 'Mittagessen', Icons.wb_sunny_rounded),
      ('dinner', 'Abendessen', Icons.nights_stay_rounded),
      ('snack', 'Snack', Icons.cookie_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: meals.map((m) {
          final isSelected = selectedMeal == m.$1;
          final brand = theme.extension<AppBrandTheme>();
          final brandColor = brand?.outline ?? theme.colorScheme.secondary;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              showCheckmark: false,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    m.$3,
                    size: 16,
                    color: isSelected ? Colors.white : brandColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(m.$2),
                ],
              ),
              selected: isSelected,
              onSelected: (s) {
                if (s) onChanged(m.$1);
              },
              selectedColor: brandColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? brandColor : theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
