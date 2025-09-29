import 'package:flutter/material.dart';

import '../theme/app_brand_theme.dart';
import '../theme/brand_on_colors.dart';
import '../theme/design_tokens.dart';

/// Outlined button that uses the branded gradient stroke while keeping the
/// surface neutral.
class BrandOutlineButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticsLabel;

  const BrandOutlineButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrandTheme>();
    if (brand == null) {
      return OutlinedButton(
        onPressed: onPressed,
        child: child,
      );
    }

    final highContrast = MediaQuery.of(context).highContrast;
    final borderRadius =
        (brand.radius ?? BorderRadius.circular(AppRadius.button)) as BorderRadius;
    final outlineWidth = brand.outlineWidth;
    final innerRadius = borderRadius - BorderRadius.circular(outlineWidth);
    final isEnabled = onPressed != null;
    final onColors = Theme.of(context).extension<BrandOnColors>();
    final foregroundColor =
        onColors?.onSecondary ?? Theme.of(context).colorScheme.secondary;

    Widget button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: highContrast ? null : brand.outlineGradient,
        color: highContrast ? brand.outlineColorFallback : null,
        borderRadius: borderRadius,
        boxShadow: isEnabled ? brand.outlineShadow : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(outlineWidth),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: innerRadius,
          child: InkWell(
            borderRadius: innerRadius,
            overlayColor: MaterialStateProperty.resolveWith((states) {
              if (!isEnabled) return Colors.transparent;
              if (states.contains(MaterialState.pressed)) {
                return brand.pressedOverlay;
              }
              if (states.contains(MaterialState.focused)) {
                return brand.focusRing.withOpacity(0.3);
              }
              return null;
            }),
            onTap: isEnabled ? onPressed : null,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: innerRadius,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: brand.height),
                child: Padding(
                  padding: brand.padding,
                  child: Center(
                    child: DefaultTextStyle.merge(
                      style: brand.textStyle.copyWith(color: foregroundColor),
                      child: IconTheme(
                        data: IconThemeData(color: foregroundColor),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!isEnabled) {
      button = Opacity(
        opacity: brand.outlineDisabledOpacity,
        child: button,
      );
    }

    if (semanticsLabel != null) {
      button = Semantics(
        button: true,
        enabled: isEnabled,
        label: semanticsLabel,
        child: button,
      );
    }

    return button;
  }
}
