import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Displays a circular XP indicator with animated progress and gradient ring.
///
/// Use this widget to visualise the user’s experience points or other
/// percentage-based metrics. It supports custom size and accepts a value
/// between 0 and 1. The progress animates smoothly when the value changes.
class CircularXpIndicator extends StatelessWidget {
  const CircularXpIndicator({
    Key? key,
    required this.progress,
    this.size = 160,
    this.label = 'XP',
  })  : assert(progress >= 0 && progress <= 1),
        super(key: key);

  /// Progress value between 0.0 and 1.0.
  final double progress;

  /// Diameter of the ring in logical pixels.
  final double size;

  /// Label displayed underneath the number (e.g. 'XP').
  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: AppDurations.medium,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: _RingPainter(progress: value),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).round()}%',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.06;
    final radius = (size.width - strokeWidth) / 2;
    final centre = Offset(size.width / 2, size.height / 2);

    // Draw background track
    final backgroundPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(centre, radius, backgroundPaint);

    // Draw progress arc with gradient
    final rect = Rect.fromCircle(center: centre, radius: radius);
    final gradient = AppGradients.progress.createShader(rect);
    final progressPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
