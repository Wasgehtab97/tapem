import 'dart:math';
import 'package:flutter/material.dart';

class ExpBadge extends StatelessWidget {
  final int expProgress; // EXP-Fortschritt in der aktuellen Division (0–999)
  final int divisionIndex; // 0 = Bronze 4, 1 = Bronze 3, etc.
  final double size;
  final VoidCallback? onPressed; // Optionaler Callback für Klickaktionen

  const ExpBadge({
    Key? key,
    required this.expProgress,
    required this.divisionIndex,
    this.size = 60,
    this.onPressed,
  }) : super(key: key);

  static const List<String> divisionNames = [
    'Bronze 4',
    'Bronze 3',
    'Bronze 2',
    'Bronze 1',
    'Silver 4',
    'Silver 3',
    'Silver 2',
    'Silver 1',
    'Gold 4',
    'Gold 3',
    'Gold 2',
    'Gold 1',
  ];

  // Für jede Division wird anhand des Modulo-4 die römische Zahl gewählt:
  static const List<String> romanNumerals = ['IV', 'III', 'II', 'I'];

  /// Bestimmt die Farbe der Division anhand des Index.
  Color _getDivisionColor() {
    if (divisionIndex < 4) {
      return const Color(0xFFCD7F32); // Bronze
    } else if (divisionIndex < 8) {
      return const Color(0xFFC0C0C0); // Silver
    } else if (divisionIndex < 12) {
      return const Color(0xFFFFD700); // Gold
    } else {
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String roman = romanNumerals[divisionIndex % romanNumerals.length];
    final Color divisionColor = _getDivisionColor();

    // Berechnung des Fortschrittsanteils (0.0 bis 1.0)
    // Der Clamp-Wert wird als double gecastet.
    final double progressFraction = (expProgress.clamp(0, 1000) as int) / 1000.0;
    const double strokeWidth = 6.0;

    // Basis-Badge
    final Widget badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        color: divisionColor.withOpacity(0.2),
      ),
      child: Center(
        child: Text(
          roman,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: divisionColor,
          ),
        ),
      ),
    );

    // Das Badge mit dem Fortschrittsrand zeichnen
    final Widget paintedBadge = CustomPaint(
      painter: _ExpBadgePainter(
        progress: progressFraction,
        color: divisionColor,
        strokeWidth: strokeWidth,
      ),
      child: badge,
    );

    // Falls ein Callback definiert ist, wird das Badge klickbar gemacht
    return onPressed != null
        ? InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(size / 2),
            child: paintedBadge,
          )
        : paintedBadge;
  }
}

class _ExpBadgePainter extends CustomPainter {
  final double progress; // Wert zwischen 0.0 und 1.0
  final Color color;
  final double strokeWidth;

  const _ExpBadgePainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - (strokeWidth / 2);
    final Paint backgroundPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final Paint foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Hintergrundkreis
    canvas.drawCircle(center, radius, backgroundPaint);
    // Fortschrittsarc, beginnend bei -pi/2 (oben)
    final double sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ExpBadgePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
