import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';

/// A circular XP gauge that animates from 0 to the provided XP value.
///
/// One full revolution (360°) corresponds to 1000 XP and therefore one level.
/// The gauge changes colour depending on how close the user is to the next
/// level: mint for low progress, turquoise for medium progress and amber for
/// high progress. A central label shows the current level, total XP and an
/// optional description (e.g. muscle name or device name).
class XpGauge extends StatelessWidget {
  /// The current XP value for this gauge.
  final int currentXp;

  /// The current level of the user. A level is reached every 1000 XP.
  final int level;

  /// A label displayed underneath the XP value (e.g. muscle group or day).
  final String label;

  /// The diameter of the gauge in logical pixels.
  final double size;

  /// Optional callback triggered when the gauge is tapped. Can be used to
  /// navigate to a detail or leaderboard page.
  final VoidCallback? onTap;

  const XpGauge({
    Key? key,
    required this.currentXp,
    required this.level,
    required this.label,
    this.size = 120.0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final gradient = brandTheme?.gradient ?? AppGradients.brandGradient;
    final onBrand = brandTheme?.onBrand ?? theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;
    final trackColor = theme.colorScheme.onSurface.withOpacity(0.18);
    final xpFormatter = NumberFormat.compact(locale: locale);
    final xpPerLevel = LevelService.xpPerLevel;
    final double progress = (currentXp % xpPerLevel) / xpPerLevel;
    final double strokeWidth = size * 0.12;
    final xpLabel = xpFormatter.format(currentXp);
    final semanticsLabel =
        '$label, Level $level, ${NumberFormat.decimalPattern(locale).format(currentXp)} XP';

    Widget gauge = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _XpGaugePainter(
              progress: progress.clamp(0.0, 1.0),
              gradient: gradient,
              trackColor: trackColor,
              strokeWidth: strokeWidth,
            ),
          ),
          Container(
            width: size * 0.64,
            height: size * 0.64,
            decoration: BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: size * 0.2,
                  offset: Offset(0, size * 0.08),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lv. $level',
                style: theme.textTheme.titleMedium?.copyWith(
                      color: onBrand,
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w700,
                    ) ??
                    TextStyle(
                      color: onBrand,
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '$xpLabel XP',
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: onBrand.withOpacity(0.86),
                      fontSize: size * 0.16,
                      fontWeight: FontWeight.w600,
                    ) ??
                    TextStyle(
                      color: onBrand.withOpacity(0.86),
                      fontSize: size * 0.16,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                      color: onBrand.withOpacity(0.72),
                      fontSize: size * 0.14,
                      letterSpacing: 0.2,
                    ) ??
                    TextStyle(
                      color: onBrand.withOpacity(0.72),
                      fontSize: size * 0.14,
                      letterSpacing: 0.2,
                    ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      gauge = Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: gauge,
        ),
      );
    }

    return Semantics(
      label: semanticsLabel,
      button: onTap != null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(size * 0.08),
        decoration: BoxDecoration(
          color: surface,
          shape: BoxShape.circle,
          border: Border.all(color: trackColor.withOpacity(0.5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: size * 0.25,
              offset: Offset(0, size * 0.14),
            ),
          ],
        ),
        child: gauge,
      ),
    );
  }
}

class _XpGaugePainter extends CustomPainter {
  const _XpGaugePainter({
    required this.progress,
    required this.gradient,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Gradient gradient;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide / 2) - (strokeWidth / 2);
    final startAngle = -math.pi / 2;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi,
      false,
      trackPaint,
    );

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius + strokeWidth / 2),
      );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _XpGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.gradient != gradient ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
