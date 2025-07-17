import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';
import '../../../../core/providers/muscle_group_provider.dart';
import '../../domain/models/muscle_group.dart';
import 'package:provider/provider.dart';

class BodyHeatmap3D extends StatelessWidget {
  const BodyHeatmap3D({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MuscleGroupProvider>();

    final maxCount = prov.counts.values.isEmpty
        ? 0
        : prov.counts.values.reduce((a, b) => a > b ? a : b);

    // simple mapping of intensity to color
    Color intensityColor(double value) =>
        Color.lerp(Colors.grey.shade300, Colors.red, value) ?? Colors.red;

    return SizedBox(
      height: 300,
      child: Cube(onSceneCreated: (scene) {
        final obj = Object(fileName: 'assets/models/body.obj');
        // apply color based on overall intensity (placeholder)
        final intensity = maxCount > 0 ? prov.counts.values.reduce((a, b) => a + b) / (maxCount * prov.counts.length) : 0.0;
        obj.updateTexture(MeshTexture(color: intensityColor(intensity)));
        scene.world.add(obj);
        scene.camera.zoom = 10;
      }),
    );
  }
}
