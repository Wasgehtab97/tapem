import 'package:flutter/material.dart';

import '../theme/app_brand_theme.dart';
import '../theme/design_tokens.dart';

/// Primary call-to-action button using the global brand gradient.
class BrandPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticsLabel;

  const BrandPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).extension<AppBrandTheme>();
    final radius = surface?.radius ?? BorderRadius.circular(AppRadius.button);
    final gradient = surface?.gradient ?? AppGradients.brandGradient;
    final shadow = surface?.shadow;
    final overlay = surface?.pressedOverlay ?? Colors.black26;
    final onBrand = surface?.onBrand ?? Colors.white;
    final textStyle = surface?.textStyle;
    final height = surface?.height ?? 48;
    final padding = surface?.padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.sm);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: radius,
        boxShadow: shadow,
      ),
      child: Semantics(
        button: true,
        label: semanticsLabel,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            splashColor: overlay,
            highlightColor: overlay,
            onTap: onPressed,
            child: Container(
              height: height,
              padding: padding,
              alignment: Alignment.center,
              child: DefaultTextStyle.merge(
                style: (textStyle ?? const TextStyle(fontWeight: FontWeight.bold))
                    .copyWith(color: onBrand),
                child: IconTheme(
                  data: IconThemeData(color: onBrand),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
