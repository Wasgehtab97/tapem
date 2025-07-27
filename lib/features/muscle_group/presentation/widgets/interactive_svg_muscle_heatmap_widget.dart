import 'package:flutter/material.dart';

import 'svg_muscle_heatmap_widget.dart';

/// Displays the muscle heatmap and adds translucent hit regions so that each
/// muscle group can be tapped individually.
class InteractiveSvgMuscleHeatmapWidget extends StatelessWidget {
  final Map<String, Color> colors;
  final void Function(String id)? onRegionTap;
  final String assetPath;

  const InteractiveSvgMuscleHeatmapWidget({
    Key? key,
    required this.colors,
    this.onRegionTap,
    this.assetPath = 'assets/body_front.svg',
  }) : super(key: key);

  // Normalised bounding boxes for each region (based on the 200x408 viewBox).
  static const Map<String, Rect> _bounds = {
    'head': Rect.fromLTWH(72, 12, 56, 56),
    'chest': Rect.fromLTWH(40, 70, 120, 50),
    'upper_arm_left': Rect.fromLTWH(20, 90, 15, 90),
    'upper_arm_right': Rect.fromLTWH(165, 90, 15, 90),
    'forearm_left': Rect.fromLTWH(20, 180, 10, 120),
    'forearm_right': Rect.fromLTWH(170, 180, 10, 120),
    'core': Rect.fromLTWH(60, 120, 80, 80),
    'pelvis': Rect.fromLTWH(60, 200, 80, 40),
    'thigh_left': Rect.fromLTWH(60, 240, 25, 140),
    'thigh_right': Rect.fromLTWH(115, 240, 25, 140),
    'calf_left': Rect.fromLTWH(60, 380, 15, 20),
    'calf_right': Rect.fromLTWH(125, 380, 15, 20),
    'foot_left': Rect.fromLTWH(58, 400, 24, 8),
    'foot_right': Rect.fromLTWH(118, 400, 24, 8),
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final scaleX = constraints.maxWidth / 200;
      // The SVG height is fixed to 400 while the viewBox height is 408.
      const scaleY = 400 / 408;

      return Stack(
        children: [
          SvgMuscleHeatmapWidget(colors: colors, assetPath: assetPath),
          for (final entry in _bounds.entries)
            Positioned(
              left: entry.value.left * scaleX,
              top: entry.value.top * scaleY,
              width: entry.value.width * scaleX,
              height: entry.value.height * scaleY,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => onRegionTap?.call(entry.key),
              ),
            ),
        ],
      );
    });
  }
}
