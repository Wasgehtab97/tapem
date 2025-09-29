import 'package:flutter/material.dart';

import '../theme/app_brand_theme.dart';
import '../theme/design_tokens.dart';
import 'brand_outline.dart';

/// Button styled with the branded outline surface.
///
/// Uses the outline tokens from [AppBrandTheme] to ensure consistent spacing,
/// typography and interaction behaviour across the app.
class BrandOutlineButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticsLabel;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const BrandOutlineButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticsLabel,
    this.padding,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrandTheme>();
    final effectivePadding =
        padding ?? brand?.padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.sm);
    final effectiveHeight = height ?? brand?.height ?? 48.0;
    final outlineColor = brand?.outline ?? Theme.of(context).colorScheme.primary;
    final textStyle = brand?.textStyle ?? const TextStyle(fontWeight: FontWeight.bold);

    final buttonContent = BrandOutline(
      onTap: onPressed,
      isDisabled: onPressed == null,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: effectiveHeight,
        child: Padding(
          padding: effectivePadding,
          child: Center(
            child: DefaultTextStyle.merge(
              style: textStyle.copyWith(color: outlineColor),
              child: IconTheme(
                data: IconThemeData(color: outlineColor),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticsLabel,
      child: buttonContent,
    );
  }
}
