import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tapem/core/theme/avatar_ring_theme.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';

class DailyXpAvatar extends StatelessWidget {
  const DailyXpAvatar({
    Key? key,
    required this.image,
    required this.size,
    required this.xp,
    required this.level,
  }) : super(key: key);

  final ImageProvider image;
  final double size;
  final int xp;
  final int level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AvatarRingTheme>() ?? AvatarRingTheme.fallback;
    final stroke = theme.strokeWidth;
    final progress = level >= LevelService.maxLevel
        ? 1.0
        : xp / LevelService.xpPerLevel;
    final badgeText = _toRoman(level);
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: progress,
              trackColor: theme.trackColor,
              gradient: theme.progressGradient,
              strokeWidth: stroke,
            ),
          ),
        ),
        CircleAvatar(
          radius: size / 2 - stroke / 2,
          backgroundImage: image,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Semantics(
            label: 'Level $level',
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                badgeText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _toRoman(int number) {
    const Map<int, String> romans = {
      1000: 'M',
      900: 'CM',
      500: 'D',
      400: 'CD',
      100: 'C',
      90: 'XC',
      50: 'L',
      40: 'XL',
      10: 'X',
      9: 'IX',
      5: 'V',
      4: 'IV',
      1: 'I',
    };
    var result = '';
    var remaining = number;
    romans.forEach((value, numeral) {
      while (remaining >= value) {
        result += numeral;
        remaining -= value;
      }
    });
    return result;
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.gradient,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final LinearGradient gradient;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.width - strokeWidth) / 2;
    final centre = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: centre, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(centre, radius, trackPaint);

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gradient != gradient;
  }
}
