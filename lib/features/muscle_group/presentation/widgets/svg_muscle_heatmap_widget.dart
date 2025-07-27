import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A widget that loads an SVG silhouette of the human body and recolours each
/// muscle region based on the provided XP values. The SVG must define a group
/// with a unique `id` for each muscle region. Colours are interpolated between
/// mint and amber depending on the XP ratio of that region.
class SvgMuscleHeatmapWidget extends StatelessWidget {
  /// Mapping of muscle ids to the accumulated XP of that region.
  final Map<String, double> xpMap;

  /// Cached Future for loading the SVG asset only once.
  static final Future<String> _svgFuture =
      rootBundle.loadString('assets/muscle_heatmap_new.svg');

  const SvgMuscleHeatmapWidget({Key? key, required this.xpMap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _svgFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        String svgString = snapshot.data!;

        final values = xpMap.values;
        if (values.isNotEmpty) {
          final minXp = values.reduce((a, b) => a < b ? a : b);
          final maxXp = values.reduce((a, b) => a > b ? a : b);
          const mintColor = Color(0xFF00E676);
          const amberColor = Color(0xFFFFC107);

          xpMap.forEach((id, xp) {
            double t = 0;
            if (maxXp > minXp) {
              t = (xp - minXp) / (maxXp - minXp);
              t = t.clamp(0, 1);
            }
            final color = Color.lerp(mintColor, amberColor, t)!;
            final hex = color.value
                .toRadixString(16)
                .padLeft(8, '0')
                .substring(2)
                .toUpperCase();
            final regex = RegExp('<[^>]*id="$id"[^>]*fill="#?[0-9A-Fa-f]{6}"');
            svgString = svgString.replaceAllMapped(regex, (match) {
              final original = match.group(0)!;
              return original.replaceAll(
                RegExp('fill="#?[0-9A-Fa-f]{6}"'),
                'fill="#${hex}"',
              );
            });
          });
        }

        return Center(
          child: SvgPicture.string(
            svgString,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}
