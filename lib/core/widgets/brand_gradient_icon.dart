import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Icon widget that paints its glyph using the global brand gradient.
class BrandGradientIcon extends StatelessWidget {
  const BrandGradientIcon(
    this.icon, {
    super.key,
    this.size,
    this.gradient,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.textDirection,
  });

  /// Icon to render using the brand gradient.
  final IconData icon;

  /// Optional size override, matches [Icon.size].
  final double? size;

  /// Optional gradient override. Falls back to [AppGradients.brandGradient].
  final Gradient? gradient;

  /// Alignment for the gradient shader.
  final AlignmentGeometry alignment;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  /// Optional explicit text direction override.
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? AppGradients.brandGradient;
    return ShaderMask(
      shaderCallback: (bounds) {
        final rect = bounds.isEmpty
            ? const Rect.fromLTWH(0, 0, 1, 1)
            : Rect.fromLTWH(0, 0, bounds.width, bounds.height);
        return effectiveGradient.createShader(rect);
      },
      blendMode: BlendMode.srcIn,
      child: Icon(
        icon,
        size: size,
        semanticLabel: semanticLabel,
        textDirection: textDirection,
        color: Colors.white,
      ),
    );
  }
}
