import 'dart:math';
import 'package:flutter/material.dart';

/// Ein Badge, das den EXP-Fortschritt innerhalb einer Division grafisch
/// als Ring anzeigt und die römische Divisionsstufe darstellt.
class ExpBadge extends StatelessWidget {
  /// EXP-Fortschritt in der aktuellen Division (0–1000).
  final int expProgress;

  /// Index der Division (0 = Bronze 4, …, 11 = Gold 1).
  final int divisionIndex;

  /// Durchmesser des Badges in Pixeln.
  final double size;

  /// Optionaler Callback, wenn das Badge angetippt wird.
  final VoidCallback? onPressed;

  const ExpBadge({
    Key? key,
    required this.expProgress,
    required this.divisionIndex,
    this.size = 60,
    this.onPressed,
  }) : super(key: key);

  static const List<String> _romanNumerals = ['IV', 'III', 'II', 'I'];

  Color _divisionColor() {
    if (divisionIndex < 4) {
      return const Color(0xFFCD7F32); // Bronze
    } else if (divisionIndex < 8) {
      return const Color(0xFFC0C0C0); // Silver
    } else {
      return const Color(0xFFFFD700); // Gold
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _divisionColor();
    final roman = _romanNumerals[divisionIndex % _romanNumerals.length];
    final progress = (expProgress.clamp(0, 1000) as int) / 1000.0;
    const strokeWidth = 6.0;

    Widget badge = CustomPaint(
      painter: _ExpBadgePainter(
        progress: progress,
        color: color,
        strokeWidth: strokeWidth,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.2),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(
            roman,
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );

    if (onPressed != null) {
      badge = InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: badge,
      );
    }

    return badge;
  }
}

class _ExpBadgePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  const _ExpBadgePainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    final backgroundPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    final sweep = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweep,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ExpBadgePainter old) {
    return old.progress != progress ||
        old.color != color ||
        old.strokeWidth != strokeWidth;
  }
}
