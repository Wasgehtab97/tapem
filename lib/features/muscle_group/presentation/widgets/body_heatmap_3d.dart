import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart' as cube;

class BodyHeatmap3D extends StatelessWidget {
  const BodyHeatmap3D({super.key});

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      height: 300,
      child: cube.Cube(onSceneCreated: (scene) {
        final obj = cube.Object(fileName: 'assets/models/body.obj');
        // TODO: apply color based on overall intensity once texture update API is available
        scene.world.add(obj);
        scene.camera.zoom = 10;
      }),
    );
  }
}
