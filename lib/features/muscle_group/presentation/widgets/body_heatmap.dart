import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/muscle_group_provider.dart';
import '../../domain/models/muscle_group.dart';

class _BodyHeatmapPainter extends CustomPainter {
  final Map<MuscleRegion, double> intensities;
  _BodyHeatmapPainter(this.intensities);

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

    // Silhouette
    final body = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(w * 0.5, h * 0.05), radius: h * 0.05))
      ..addRect(Rect.fromLTWH(w * 0.45, h * 0.1, w * 0.1, h * 0.15))
      ..addRect(Rect.fromLTWH(w * 0.4, h * 0.25, w * 0.2, h * 0.35))
      ..addRect(Rect.fromLTWH(w * 0.2, h * 0.25, w * 0.1, h * 0.45))
      ..addRect(Rect.fromLTWH(w * 0.7, h * 0.25, w * 0.1, h * 0.45))
      ..addRect(Rect.fromLTWH(w * 0.45, h * 0.6, w * 0.1, h * 0.35))
      ..addRect(Rect.fromLTWH(w * 0.55, h * 0.6, w * 0.1, h * 0.35));
    fill.color = _baseColor;
    canvas.drawPath(body, fill);

    void drawRegion(Path path, MuscleRegion region) {
      fill.color = _color(intensities[region] ?? 0);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }

    // Shoulders
    final shoulders = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.25, h * 0.1, w * 0.5, h * 0.08),
          Radius.circular(h * 0.02)));
    drawRegion(shoulders, MuscleRegion.shoulders);

    // Chest
    final chest = Path()
      ..addRect(Rect.fromLTWH(w * 0.32, h * 0.18, w * 0.36, h * 0.12));
    drawRegion(chest, MuscleRegion.chest);

    // Arms
    final leftArm = Path()
      ..addRect(Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.1, h * 0.45));
    final rightArm = Path()
      ..addRect(Rect.fromLTWH(w * 0.72, h * 0.18, w * 0.1, h * 0.45));
    drawRegion(leftArm, MuscleRegion.arms);
    drawRegion(rightArm, MuscleRegion.arms);

    // Core
    final core = Path()
      ..addRect(Rect.fromLTWH(w * 0.4, h * 0.32, w * 0.2, h * 0.18));
    drawRegion(core, MuscleRegion.core);

    // Legs
    final leftLeg = Path()
      ..addRect(Rect.fromLTWH(w * 0.44, h * 0.52, w * 0.1, h * 0.38));
    final rightLeg = Path()
      ..addRect(Rect.fromLTWH(w * 0.56, h * 0.52, w * 0.1, h * 0.38));
    drawRegion(leftLeg, MuscleRegion.legs);
    drawRegion(rightLeg, MuscleRegion.legs);

    // Back (shown as same as chest for simplicity)
    final back = Path()
      ..addRect(Rect.fromLTWH(w * 0.32, h * 0.18, w * 0.36, h * 0.12));
    drawRegion(back, MuscleRegion.back);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BodyHeatmap extends StatelessWidget {
  const BodyHeatmap({Key? key}) : super(key: key);

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

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: CustomPaint(
            painter: _BodyHeatmapPainter(intensities),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 16),
        for (final g in prov.groups)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(g.name)),
                Text((prov.counts[g.id] ?? 0).toString()),
              ],
            ),
          ),
      ],
    );
  }
}
