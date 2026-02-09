import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';

class NutritionOverviewCard extends StatelessWidget {
  final DateTime date;
  final int goal;
  final int total;
  final int protein;
  final int carbs;
  final int fat;

  const NutritionOverviewCard({
    super.key,
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
    final brandGradient = brand?.gradient ?? AppGradients.brandGradient;
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;
    final macroAccentColor = nutritionBrandAccentColor(context);
    final dateLabel = DateFormat.yMMMd().format(date);
    final remaining = goal - total;
    final progress = goal > 0 ? (total / goal).clamp(0, 2).toDouble() : 0.0;
    final progressPercent = goal > 0 ? (progress * 100).round() : 0;
    final statusColor = macroAccentColor;
    final headerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(theme.colorScheme.surface, brandGradient.colors.first, 0.12)!
            .withOpacity(0.58),
        theme.colorScheme.surface.withOpacity(0.34),
      ],
    );

    return BrandInteractiveCard(
      padding: EdgeInsets.zero,
      showShadow: false,
      showPressedOverlay: false,
      enableScaleAnimation: false,
      restingBorderColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.cardLg),
          gradient: headerGradient,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateLabel,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 116,
                  height: 116,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: _CalorieRing(
                          total: total.toDouble(),
                          goal: goal.toDouble(),
                          progressGradient: LinearGradient(
                            colors: [
                              AppColors.accentTurquoise,
                              brandColor,
                            ],
                          ),
                          trackColor: theme.colorScheme.onSurface.withOpacity(0.12),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$progressPercent%',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'vom Ziel',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.62),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    children: [
                      _KcalMetricTile(
                        icon: Icons.flag_outlined,
                        label: 'Ziel',
                        value: '$goal kcal',
                        color: theme.colorScheme.onSurface.withOpacity(0.82),
                      ),
                      const SizedBox(height: 8),
                      _KcalMetricTile(
                        icon: Icons.local_fire_department_outlined,
                        label: 'Gesamt',
                        value: '$total kcal',
                        color: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(height: 8),
                      _KcalMetricTile(
                        icon: Icons.bolt_rounded,
                        label: 'Freie kcal',
                        value: '$remaining',
                        color: statusColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MacroSummaryPill(
                  label: 'Protein',
                  shortLabel: 'P',
                  value: '$protein g',
                  color: macroAccentColor,
                ),
                _MacroSummaryPill(
                  label: 'Kohlenhydrate',
                  shortLabel: 'C',
                  value: '$carbs g',
                  color: macroAccentColor,
                ),
                _MacroSummaryPill(
                  label: 'Fett',
                  shortLabel: 'F',
                  value: '$fat g',
                  color: macroAccentColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalorieRing extends StatelessWidget {
  final double total;
  final double goal;
  final LinearGradient progressGradient;
  final Color trackColor;

  const _CalorieRing({
    required this.total,
    required this.goal,
    required this.progressGradient,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (total / goal).clamp(0.0, 2.0) : 0.0;
    return CustomPaint(
      painter: _DayCalorieRingPainter(
        progress: progress,
        progressGradient: progressGradient,
        trackColor: trackColor,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _DayCalorieRingPainter extends CustomPainter {
  final double progress;
  final LinearGradient progressGradient;
  final Color trackColor;

  _DayCalorieRingPainter({
    required this.progress,
    required this.progressGradient,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 6;
    const strokeWidth = 12.0;
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final primarySweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    final primaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: progressGradient.colors
            .map((c) => c.withOpacity(0.95))
            .toList(growable: false),
        stops: progressGradient.stops,
        transform: GradientRotation(-math.pi / 2),
      ).createShader(arcRect);
    canvas.drawArc(arcRect, startAngle, primarySweep, false, primaryPaint);

    if (progress > 1.0) {
      final overflowSweep = 2 * math.pi * (progress - 1.0).clamp(0.0, 1.0);
      final overflowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = AppColors.accentAmber.withOpacity(0.95);
      canvas.drawArc(arcRect, startAngle, overflowSweep, false, overflowPaint);
    }

    final tipAngle = startAngle + primarySweep;
    final tipCenter = Offset(
      center.dx + radius * math.cos(tipAngle),
      center.dy + radius * math.sin(tipAngle),
    );
    canvas.drawCircle(
      tipCenter,
      4,
      Paint()
        ..color = progress > 1.0
            ? AppColors.accentAmber
            : progressGradient.colors.last.withOpacity(0.95),
    );
  }

  @override
  bool shouldRepaint(covariant _DayCalorieRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressGradient != progressGradient;
  }
}

class _KcalMetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KcalMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: theme.colorScheme.onSurface.withOpacity(0.72),
          ),
          const SizedBox(width: 6),
          Text(
            '$label:',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.68),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroSummaryPill extends StatelessWidget {
  final String label;
  final String shortLabel;
  final String value;
  final Color color;

  const _MacroSummaryPill({
    required this.label,
    required this.shortLabel,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$shortLabel ·',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.58),
            ),
          ),
        ],
      ),
    );
  }
}
