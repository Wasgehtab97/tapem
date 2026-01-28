import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/app_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/nutrition/providers/nutrition_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:intl/intl.dart';

class NutritionHomeScreen extends ConsumerStatefulWidget {
  const NutritionHomeScreen({super.key});

  @override
  ConsumerState<NutritionHomeScreen> createState() => _NutritionHomeScreenState();
}

class _NutritionHomeScreenState extends ConsumerState<NutritionHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadToday());
  }

  Future<void> _loadToday() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.userId;
    if (uid == null || uid.isEmpty) return;
    await ref.read(nutritionProvider).loadDay(uid, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(nutritionProvider);
    final goal = state.goal?.kcal ?? 0;
    final total = state.log?.total.kcal ?? 0;
    final date = state.selectedDate;
    final protein = state.log?.total.protein ?? 0;
    final carbs = state.log?.total.carbs ?? 0;
    final fat = state.log?.total.fat ?? 0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.lg,
          ),
          children: [
            // Premium hero header card
            _NutritionHeroCard(
              date: date,
              goal: goal,
              total: total,
              protein: protein,
              carbs: carbs,
              fat: fat,
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Action tiles with premium design
            NutritionActionTile(
              icon: Icons.bar_chart_rounded,
              title: 'Tagesübersicht',
              subtitle: 'Kalorien und Makros im Blick.',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouter.nutritionDay),
            ),
            NutritionActionTile(
              icon: Icons.tune_rounded,
              title: loc.nutritionHomeGoalsTitle,
              subtitle: 'Kalorien definieren.',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouter.nutritionGoals),
            ),
            NutritionActionTile(
              icon: Icons.restaurant_menu_rounded,
              title: 'Gerichte',
              subtitle: 'Eigene Rezepte speichern und hinzufügen.',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouter.nutritionRecipes),
            ),
            NutritionActionTile(
              icon: Icons.calendar_month_rounded,
              title: loc.nutritionHomeCalendarTitle,
              subtitle: 'Tage unter/auf/über Ziel sehen.',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouter.nutritionCalendar),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Attribution section
            NutritionSectionTitle(title: loc.nutritionAttributionTitle),
            NutritionCard(
              neutral: true,
              enableGlow: false,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Produktdaten stammen aus Open Food Facts und stehen unter der Open Database License (ODbL) 1.0. Eine Namensnennung ist erforderlich.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _AttributionLink(
                        label: 'Open Food Facts',
                        url: 'https://world.openfoodfacts.org/',
                      ),
                      _AttributionLink(
                        label: 'ODbL 1.0',
                        url: 'https://opendatacommons.org/licenses/odbl/1-0/',
                      ),
                      _AttributionLink(
                        label: 'Lizenzdetails',
                        url:
                            'https://world.openfoodfacts.org/legal/licence#content',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium hero card with glassmorphism effect and calorie ring
class _NutritionHeroCard extends StatelessWidget {
  final DateTime date;
  final int goal;
  final int total;
  final int protein;
  final int carbs;
  final int fat;

  const _NutritionHeroCard({
    required this.date,
    required this.goal,
    required this.total,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;
    
    // Calculate progress
    final progress = goal > 0 ? (total / goal).clamp(0.0, 1.0) : 0.0;
    final isOnTarget = goal > 0 && (total - goal).abs() <= goal * 0.05;

    return HeroGradientCard(
      enableBackdropBlur: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Date header
          Row(
            children: [
              BrandGradientIcon(Icons.calendar_today_rounded, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  DateFormat.yMMMMd('de').format(date),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Calorie stats with animated ring
          Row(
            children: [
              // Calorie ring
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    painter: _CalorieRingPainter(
                      progress: progress,
                      brandColor: brandColor,
                      isOnTarget: isOnTarget,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedNutritionStat(
                            value: total,
                            label: 'kcal',
                            enableFlicker: isOnTarget,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'von $goal',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Macro pills - with reduced spacing to prevent overflow
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MacroPill(
                label: 'P',
                value: '${protein}g',
                color: Colors.redAccent,
                enableGlow: false,
              ),
              MacroPill(
                label: 'C',
                value: '${carbs}g',
                color: AppColors.accentMint,
                enableGlow: false,
              ),
              MacroPill(
                label: 'F',
                value: '${fat}g',
                color: AppColors.accentAmber,
                enableGlow: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for calorie ring with brand gradient
class _CalorieRingPainter extends CustomPainter {
  final double progress;
  final Color brandColor;
  final bool isOnTarget;

  _CalorieRingPainter({
    required this.progress,
    required this.brandColor,
    required this.isOnTarget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    final strokeWidth = 12.0;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      // Brand gradient for progress arc
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        colors: [
          AppColors.accentMint,
          AppColors.accentTurquoise,
          AppColors.accentAmber,
          AppColors.accentMint,
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
        transform: const GradientRotation(-1.5708), // Start from top
      );

      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Glow effect for on-target state
      if (isOnTarget) {
        final glowPaint = Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

        canvas.drawArc(
          rect,
          -1.5708, // Start from top
          progress * 6.2832, // Full circle = 2π
          false,
          glowPaint,
        );
      }

      canvas.drawArc(
        rect,
        -1.5708,
        progress * 6.2832,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CalorieRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.brandColor != brandColor ||
        oldDelegate.isOnTarget != isOnTarget;
  }
}

class _AttributionLink extends StatelessWidget {
  final String label;
  final String url;

  const _AttributionLink({
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final color = brand?.outline ?? theme.colorScheme.secondary;
    
    Future<void> openLink() async {
      final uri = Uri.parse(url);
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Link konnte nicht geöffnet werden: $label'),
          ),
        );
      }
    }

    return ActionChip(
      label: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          decoration: TextDecoration.underline,
          decorationColor: color.withOpacity(0.5),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.6),
      side: BorderSide(color: color.withOpacity(0.25)),
      onPressed: openLink,
      avatar: Icon(Icons.link_rounded, size: 16, color: color),
      pressElevation: 1,
      visualDensity: VisualDensity.compact,
    );
  }
}
