import 'package:flutter/material.dart';
import 'package:tapem/core/theme/design_tokens.dart';

/// Text widget that renders its foreground using the global brand gradient.
class BrandGradientText extends StatelessWidget {
  const BrandGradientText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = defaultStyle
        .merge(style)
        .copyWith(color: Colors.white, decoration: TextDecoration.none);

    return ShaderMask(
      shaderCallback: (bounds) {
        final rect = bounds.isEmpty
            ? const Rect.fromLTWH(0, 0, 1, 1)
            : Rect.fromLTWH(0, 0, bounds.width, bounds.height);
        return AppGradients.brandGradient.createShader(rect);
      },
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: effectiveStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
      ),
    );
  }
}
