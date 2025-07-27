import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Displays a 3D body model and applies colours to its materials based on
/// [muscleColors]. The material names should match the keys of the map.
class Mesh3DHeatmapWidget extends StatefulWidget {
  final Map<String, Color> muscleColors;
  final String assetPath;

  const Mesh3DHeatmapWidget({
    Key? key,
    required this.muscleColors,
    this.assetPath = 'assets/models/body.gltf',
  }) : super(key: key);

  @override
  State<Mesh3DHeatmapWidget> createState() => _Mesh3DHeatmapWidgetState();
}

class _Mesh3DHeatmapWidgetState extends State<Mesh3DHeatmapWidget> {
  late final ModelViewerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ModelViewerController();
  }

  @override
  Widget build(BuildContext context) {
    return ModelViewer(
      src: widget.assetPath,
      ar: false,
      autoRotate: false,
      cameraControls: true,
      onModelLoaded: () {
        for (final entry in widget.muscleColors.entries) {
          _controller.setColor(entry.key, entry.value);
        }
      },
      controller: _controller,
    );
  }
}
