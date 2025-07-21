import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/muscle_group_provider.dart';
import '../../domain/models/muscle_group.dart';
import 'muscle_paths.dart';

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

  Path _mirror(Path path, double width) {
    final matrix = Matrix4.identity()
      ..scale(-1.0, 1.0)
      ..translate(width, 0.0);
    return path.transform(matrix.storage);
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
    final leftShoulder = MusclePaths.deltoidPath(size);
    final rightShoulder = _mirror(leftShoulder, w);
    drawRegion(leftShoulder, MuscleRegion.shoulders);
    drawRegion(rightShoulder, MuscleRegion.shoulders);

    // Chest
    drawRegion(MusclePaths.pectoralisPath(size), MuscleRegion.chest);

    // Biceps
    final leftBiceps = MusclePaths.bicepsPath(size);
    final rightBiceps = _mirror(leftBiceps, w);
    drawRegion(leftBiceps, MuscleRegion.arms);
    drawRegion(rightBiceps, MuscleRegion.arms);

    // Forearms
    final leftForearm = MusclePaths.forearmFlexorsPath(size);
    final rightForearm = _mirror(leftForearm, w);
    drawRegion(leftForearm, MuscleRegion.arms);
    drawRegion(rightForearm, MuscleRegion.arms);

    // Obliques
    final leftOblique = MusclePaths.obliquesPath(size);
    final rightOblique = _mirror(leftOblique, w);
    drawRegion(leftOblique, MuscleRegion.core);
    drawRegion(rightOblique, MuscleRegion.core);

    // Abs
    drawRegion(MusclePaths.rectusAbdominisPath(size), MuscleRegion.core);

    // Quadriceps
    drawRegion(MusclePaths.quadricepsPath(size), MuscleRegion.legs);

    // Vastus medialis (inner knee)
    final leftVastus = MusclePaths.vastusMedialisPath(size);
    final rightVastus = _mirror(leftVastus, w);
    drawRegion(leftVastus, MuscleRegion.legs);
    drawRegion(rightVastus, MuscleRegion.legs);

    // Tibialis anterior (shin)
    drawRegion(MusclePaths.tibialisAnteriorPath(size), MuscleRegion.legs);

    // Calves
    final leftCalf = MusclePaths.gastrocnemiusPath(size);
    final rightCalf = _mirror(leftCalf, w);
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

