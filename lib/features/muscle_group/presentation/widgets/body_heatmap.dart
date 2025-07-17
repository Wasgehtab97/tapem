import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/muscle_group_provider.dart';
import '../../domain/models/muscle_group.dart';

class _BodyHeatmapPainter extends CustomPainter {
  final Map<MuscleRegion, double> intensities;
  _BodyHeatmapPainter(this.intensities);

  Color _color(double value) =>
      Color.lerp(Colors.grey.shade300, Colors.red, value) ?? Colors.red;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // Shoulders
    paint.color = _color(intensities[MuscleRegion.shoulders] ?? 0);
    canvas.drawRect(Rect.fromLTWH(w * 0.3, h * 0.05, w * 0.4, h * 0.1), paint);

    // Chest
    paint.color = _color(intensities[MuscleRegion.chest] ?? 0);
    canvas.drawRect(Rect.fromLTWH(w * 0.3, h * 0.15, w * 0.4, h * 0.15), paint);

    // Arms
    paint.color = _color(intensities[MuscleRegion.arms] ?? 0);
    canvas.drawRect(Rect.fromLTWH(w * 0.1, h * 0.15, w * 0.2, h * 0.4), paint);
    canvas.drawRect(Rect.fromLTWH(w * 0.7, h * 0.15, w * 0.2, h * 0.4), paint);

    // Core
    paint.color = _color(intensities[MuscleRegion.core] ?? 0);
    canvas.drawRect(Rect.fromLTWH(w * 0.4, h * 0.3, w * 0.2, h * 0.2), paint);

    // Legs
    paint.color = _color(intensities[MuscleRegion.legs] ?? 0);
    canvas.drawRect(Rect.fromLTWH(w * 0.4, h * 0.5, w * 0.15, h * 0.45), paint);
    canvas.drawRect(Rect.fromLTWH(w * 0.55, h * 0.5, w * 0.15, h * 0.45), paint);

    // Back
    paint.color = _color(intensities[MuscleRegion.back] ?? 0);
    canvas.drawRect(Rect.fromLTWH(w * 0.3, h * 0.15, w * 0.4, h * 0.15), paint);
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
