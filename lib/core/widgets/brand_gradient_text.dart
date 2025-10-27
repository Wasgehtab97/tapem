import 'package:flutter/material.dart';

import '../theme/app_brand_theme.dart';

/// Text widget that renders its foreground using the global brand accent colour.
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
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accentColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = defaultStyle
        .merge(style)
        .copyWith(
          color: accentColor,
          decoration: TextDecoration.none,
        );

    return Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
