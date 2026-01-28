import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/widgets/brand_outline_button.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

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
    this.enableGlow = true,
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
      shadowColor: brandColor.withOpacity(0.15),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: BrandInteractiveCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Icon with brand gradient background
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brandColor.withOpacity(0.25),
                    brandColor.withOpacity(0.08),
                  ],
                  center: Alignment.topLeft,
                ),
                boxShadow: [
                  BoxShadow(
                    color: brandColor.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: BrandGradientIcon(icon, size: 22),
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
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            // Chevron with gradient
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brandColor.withOpacity(0.18),
                    brandColor.withOpacity(0.02),
                  ],
                  center: Alignment.topLeft,
                ),
                border: Border.all(
                  color: brandColor.withOpacity(0.3),
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: BrandGradientIcon(Icons.arrow_outward_rounded, size: 16),
              ),
            ),
          ],
        ),
      ),
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
    
    final pill = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.18),
            color.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: color.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: enableGlow
            ? [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
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
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                fontSize: 12,
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible, // show full macro amount (no "...").
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

/// Hero gradient card with glassmorphism effect
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

    // Much darker gradient for nutrition cards - blend heavily with background
    final softenedGradient = LinearGradient(
      begin: gradient.begin,
      end: gradient.end,
      colors: gradient.colors
          .map(
            (c) => Color.lerp(c, theme.scaffoldBackgroundColor, 0.85) ?? c,
          )
          .toList(growable: false),
    );

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: softenedGradient,
        borderRadius: brand?.outlineRadius ?? BorderRadius.circular(AppRadius.cardLg),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.last.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );

    if (enableBackdropBlur) {
      content = ClipRRect(
        borderRadius: brand?.outlineRadius as BorderRadius? ?? 
            BorderRadius.circular(AppRadius.cardLg),
        child: Stack(
          children: [
            content,
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: const SizedBox(),
              ),
            ),
            Padding(
              padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
              child: child,
            ),
          ],
        ),
      );
    }

    return content;
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

    // Create gradient similar to WorkoutDayScreen save button
    final gradient = enabled
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: (brand?.gradient ?? AppGradients.brandGradient).colors.map((c) {
              return Color.lerp(c, theme.scaffoldBackgroundColor, 0.35) ?? c;
            }).toList(),
          )
        : null;

    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: gradient,
        color: enabled ? null : Colors.white.withOpacity(0.05),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: brandColor.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(28),
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
                          fontSize: 17,
                          letterSpacing: 0.5,
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
