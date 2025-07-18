import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/muscle_group_provider.dart';
import '../../domain/models/muscle_group.dart';

class _AdvancedHeatmapPainter extends CustomPainter {
  final Map<MuscleRegion, double> intensities;
  _AdvancedHeatmapPainter(this.intensities);

  static const _baseColor = Color(0xFFF5F5F5);
  static const _primaryColor = Color(0xFFC80000);
  static const _secondaryColor = Color(0xFFFFC8C8);
  static const _mutedColor = Color(0xFF787878);
  static const _strokeColor = Colors.white;

  Color _color(double value) {
    if (value > 0.66) return _primaryColor;
    if (value > 0) return _secondaryColor;
    return _mutedColor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _strokeColor;

    final w = size.width;
    final h = size.height;

    final body = Path()
      ..addOval(Rect.fromCircle(center: Offset(w * 0.5, h * 0.07), radius: h * 0.07))
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.38, h * 0.14, w * 0.24, h * 0.4), Radius.circular(w * 0.05)))
      ..addRect(Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.12, h * 0.5))
      ..addRect(Rect.fromLTWH(w * 0.7, h * 0.18, w * 0.12, h * 0.5))
      ..addRect(Rect.fromLTWH(w * 0.45, h * 0.54, w * 0.1, h * 0.4))
      ..addRect(Rect.fromLTWH(w * 0.55, h * 0.54, w * 0.1, h * 0.4));
    fill.color = _baseColor;
    canvas.drawPath(body, fill);

    void drawRegion(Path path, MuscleRegion region) {
      fill.color = _color(intensities[region] ?? 0);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }

    // Shoulders
    final leftShoulder = Path()..addOval(Rect.fromLTWH(w * 0.25, h * 0.18, w * 0.15, h * 0.09));
    final rightShoulder = Path()..addOval(Rect.fromLTWH(w * 0.6, h * 0.18, w * 0.15, h * 0.09));
    drawRegion(leftShoulder, MuscleRegion.shoulders);
    drawRegion(rightShoulder, MuscleRegion.shoulders);

    // Chest
    final chest = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.37, h * 0.23, w * 0.26, h * 0.12), Radius.circular(w * 0.03)));
    drawRegion(chest, MuscleRegion.chest);

    // Biceps
    final leftBiceps = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.2, h * 0.28, w * 0.1, h * 0.14), Radius.circular(w * 0.03)));
    final rightBiceps = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.7, h * 0.28, w * 0.1, h * 0.14), Radius.circular(w * 0.03)));
    drawRegion(leftBiceps, MuscleRegion.arms);
    drawRegion(rightBiceps, MuscleRegion.arms);

    // Forearms
    final leftForearm = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.2, h * 0.42, w * 0.1, h * 0.22), Radius.circular(w * 0.03)));
    final rightForearm = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.7, h * 0.42, w * 0.1, h * 0.22), Radius.circular(w * 0.03)));
    drawRegion(leftForearm, MuscleRegion.arms);
    drawRegion(rightForearm, MuscleRegion.arms);

    // Obliques
    final leftOblique = Path()..addOval(Rect.fromLTWH(w * 0.35, h * 0.34, w * 0.07, h * 0.14));
    final rightOblique = Path()..addOval(Rect.fromLTWH(w * 0.58, h * 0.34, w * 0.07, h * 0.14));
    drawRegion(leftOblique, MuscleRegion.core);
    drawRegion(rightOblique, MuscleRegion.core);

    // Abs
    for (int i = 0; i < 3; i++) {
      final rectLeft = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.46, h * (0.3 + 0.05 * i * 2), w * 0.04, h * 0.06), Radius.circular(w * 0.015)));
      final rectRight = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.5, h * (0.3 + 0.05 * i * 2), w * 0.04, h * 0.06), Radius.circular(w * 0.015)));
      drawRegion(rectLeft, MuscleRegion.core);
      drawRegion(rectRight, MuscleRegion.core);
    }

    // Quadriceps
    final leftQuad = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.44, h * 0.54, w * 0.1, h * 0.22), Radius.circular(w * 0.05)));
    final rightQuad = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.56, h * 0.54, w * 0.1, h * 0.22), Radius.circular(w * 0.05)));
    drawRegion(leftQuad, MuscleRegion.legs);
    drawRegion(rightQuad, MuscleRegion.legs);

    // Vastus medialis (inner knee)
    final leftVastus = Path()..addOval(Rect.fromLTWH(w * 0.47, h * 0.7, w * 0.05, h * 0.05));
    final rightVastus = Path()..addOval(Rect.fromLTWH(w * 0.58, h * 0.7, w * 0.05, h * 0.05));
    drawRegion(leftVastus, MuscleRegion.legs);
    drawRegion(rightVastus, MuscleRegion.legs);

    // Tibialis anterior (shin)
    final leftShin = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.47, h * 0.75, w * 0.05, h * 0.12), Radius.circular(w * 0.02)));
    final rightShin = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.58, h * 0.75, w * 0.05, h * 0.12), Radius.circular(w * 0.02)));
    drawRegion(leftShin, MuscleRegion.legs);
    drawRegion(rightShin, MuscleRegion.legs);

    // Calves
    final leftCalf = Path()..addOval(Rect.fromLTWH(w * 0.46, h * 0.87, w * 0.06, h * 0.07));
    final rightCalf = Path()..addOval(Rect.fromLTWH(w * 0.58, h * 0.87, w * 0.06, h * 0.07));
    drawRegion(leftCalf, MuscleRegion.legs);
    drawRegion(rightCalf, MuscleRegion.legs);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AdvancedBodyHeatmap extends StatelessWidget {
  const AdvancedBodyHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MuscleGroupProvider>();

    final maxCount = prov.counts.values.isEmpty
        ? 0
        : prov.counts.values.reduce((a, b) => a > b ? a : b);

    final intensities = <MuscleRegion, double>{};
    for (final g in prov.groups) {
      final count = prov.counts[g.id] ?? 0;
      final intensity = maxCount > 0 ? count / maxCount : 0.0;
      final existing = intensities[g.region];
      if (existing == null || intensity > existing) {
        intensities[g.region] = intensity;
      }
    }

    return CustomPaint(
      painter: _AdvancedHeatmapPainter(intensities),
      child: const SizedBox(height: 350, width: double.infinity),
    );
  }
}

