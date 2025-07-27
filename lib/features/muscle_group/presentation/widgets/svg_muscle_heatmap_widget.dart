import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A widget that loads an SVG silhouette of the human body and recolours each
/// muscle region on the fly. The SVG must define an element with a unique `id`
/// for every region. For example, an element with `id="arms"` will be
/// recoloured using the entry `colors['arms']` if provided.
class SvgMuscleHeatmapWidget extends StatelessWidget {
  /// Mapping of region identifiers to the desired colour. The identifiers
  /// correspond to the `id` attributes in the SVG file. The colours should be
  /// provided without the leading `#` and using 6-digit hex notation.
  final Map<String, Color> colors;

  /// The asset path of the SVG template.
  final String assetPath;

  const SvgMuscleHeatmapWidget({
    Key? key,
    required this.colors,
    this.assetPath = 'assets/body_front.svg',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString(assetPath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        String svgString = snapshot.data!;
        // Replace the fill colour of each element by searching for the id and
        // replacing the following fill attribute.
        colors.forEach((id, color) {
          final hex = color.value.toRadixString(16).padLeft(8, '0').substring(2);
          final regex = RegExp('<[^>]*id="$id"[^>]*fill="#?[0-9A-Fa-f]{6}"');
          svgString = svgString.replaceAllMapped(regex, (match) {
            final original = match.group(0)!;
            return original.replaceAll(
              RegExp('fill="#?[0-9A-Fa-f]{6}"'),
              'fill="#${hex.toUpperCase()}"',
            );
          });
        });
        return SvgPicture.string(
          svgString,
          width: double.infinity,
          height: 400,
        );
      },
    );
  }
}
