import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

/// Displays a muscle heatmap based on an SVG asset.
///
/// Colors are interpolated between [_mintColor] and [_amberColor] according
/// to the XP values provided via [xpMap]. The SVG asset is cached after the
/// first load for performance.
class SvgMuscleHeatmapWidget extends StatelessWidget {
  final Map<String, double> xpMap;
  const SvgMuscleHeatmapWidget({super.key, required this.xpMap});

  static const Color _mintColor = Color(0xFF98FF98); // mint
  static const Color _amberColor = Color(0xFFFFCA28); // amber

  static String? _baseSvg;

  Future<String> _coloredSvg() async {
    _baseSvg ??= await rootBundle.loadString('assets/muscle_heatmap.svg');
    var svg = _baseSvg!;

    if (xpMap.isEmpty) return svg;

    final values = xpMap.values;
    final minXp = values.reduce(math.min);
    final maxXp = values.reduce(math.max);
    final diff = (maxXp - minXp) == 0 ? 1.0 : (maxXp - minXp);

    xpMap.forEach((id, xp) {
      final t = ((xp - minXp) / diff).clamp(0.0, 1.0);
      final color = Color.lerp(_mintColor, _amberColor, t)!;
      final hex = '#'
          '${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
      final reg = RegExp('id="'
          '$id'
          '"([^>]*)fill="[^\"]*"');
      svg = svg.replaceAllMapped(reg, (m) => 'id="$id"${m[1]}fill="$hex"');
    });

    return svg;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _coloredSvg(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Center(
          child: SvgPicture.string(
            snapshot.data!,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}
