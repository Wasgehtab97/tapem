import 'package:flutter/material.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/features/muscle_group/presentation/widgets/muscle_paths.dart';

/// A custom painter that draws a two–dimensional human silhouette and colours
/// each muscle region based on provided intensity values. The colours follow
/// the mint→turquoise→amber gradient specified in the design guide. Regions
/// with no XP are rendered in a muted grey tone.
class _HeatmapPainter extends CustomPainter {
  final Map<MuscleRegion, double> intensities;
  _HeatmapPainter(this.intensities);

  // Base shape of the body (head, torso and limbs) in a muted grey.
  static const _baseColor = Color(0xFF2A2A2A);
  static const _mutedColor = Color(0xFF555555);

  // Gradient colours for low→medium→high intensity.
  static const _mint = Color(0xFF00E676);
  static const _turquoise = Color(0xFF00BCD4);
  static const _amber = Color(0xFFFFC107);

  Color _color(double value) {
    if (value <= 0.0) return _mutedColor;
    if (value <= 0.5) {
      final t = value / 0.5;
      return Color.lerp(_mutedColor, _mint, t)!;
    } else if (value <= 0.8) {
      final t = (value - 0.5) / 0.3;
      return Color.lerp(_mint, _turquoise, t)!;
    } else {
      final t = (value - 0.8) / 0.2;
      return Color.lerp(_turquoise, _amber, t.clamp(0.0, 1.0))!;
    }
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
      ..color = Colors.black.withOpacity(0.5);

    final w = size.width;
    final h = size.height;

    // Draw base silhouette
    final body = Path()
      ..addOval(Rect.fromCircle(center: Offset(w * 0.5, h * 0.07), radius: h * 0.07))
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.38, h * 0.14, w * 0.24, h * 0.4),
          Radius.circular(w * 0.05)))
      ..addRect(Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.12, h * 0.5))
      ..addRect(Rect.fromLTWH(w * 0.70, h * 0.18, w * 0.12, h * 0.5))
      ..addRect(Rect.fromLTWH(w * 0.45, h * 0.54, w * 0.10, h * 0.4))
      ..addRect(Rect.fromLTWH(w * 0.55, h * 0.54, w * 0.10, h * 0.4));
    fill.color = _baseColor;
    canvas.drawPath(body, fill);

    void drawRegion(Path path, MuscleRegion region) {
      final intensity = intensities[region] ?? 0.0;
      fill.color = _color(intensity);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }

    // Shoulders (deltoid)
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

/// A widget that wraps [_HeatmapPainter] and exposes a simple API: pass
/// normalised intensities for each muscle region and the widget draws
/// a colourised silhouette. The widget has a fixed height but stretches
/// horizontally to fill its parent.
class BodyHeatmapWidget extends StatelessWidget {
  /// A map containing normalised intensity values (0.0–1.0) for each
  /// [MuscleRegion]. Keys missing from this map are treated as 0.0.
  final Map<MuscleRegion, double> intensities;

  const BodyHeatmapWidget({Key? key, required this.intensities}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HeatmapPainter(intensities),
      child: const SizedBox(
        width: double.infinity,
        height: 350,
      ),
    );
  }
}
