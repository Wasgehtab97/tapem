import 'package:flutter/material.dart';

import '../theme/app_brand_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/brand_on_colors.dart';

/// Primary call-to-action button using the global brand gradient.
class BrandPrimaryButton extends StatefulWidget {
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
  State<BrandPrimaryButton> createState() => _BrandPrimaryButtonState();
}

class _BrandPrimaryButtonState extends State<BrandPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.extension<AppBrandTheme>();
    final onBrand = theme.extension<BrandOnColors>()?.onCta ?? Colors.black;

    // `InkWell` requires a [BorderRadius], while the theme exposes a
    // [BorderRadiusGeometry]. Cast to [BorderRadius] so the same radius can
    // be used for the decoration and the ink ripple.
    final borderRadius =
        (surface?.radius ?? BorderRadius.circular(AppRadius.button))
            as BorderRadius;
    final baseGradient = surface?.gradient ?? AppGradients.brandGradient;
    final baseShadow = surface?.shadow;
    final overlay = surface?.pressedOverlay ?? Colors.black26;
    final textStyle = surface?.textStyle;
    final height = surface?.height ?? 48;
    final padding = surface?.padding ??
        const EdgeInsets.symmetric(horizontal: AppSpacing.sm);
    final isEnabled = widget.onPressed != null;
    final flickerIntensity = surface?.flickerIntensity ?? 0.0;
    final hasFlicker = flickerIntensity > 0 && isEnabled;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = hasFlicker
            ? (1 - flickerIntensity) +
                (_controller.value * 2 * flickerIntensity)
            : 1.0;
        final flickerOpacity = hasFlicker
            ? (1 - flickerIntensity * 0.75) +
                (_controller.value * flickerIntensity * 0.75)
            : 1.0;

        // Subtiles Flackern nur für das Flame-Theme:
        // - leicht variierende Schattenintensität
        // - minimal flackernder Gradient.
        final gradient = hasFlicker
            ? LinearGradient(
                begin: baseGradient.begin,
                end: baseGradient.end,
                colors: [
                  Color.lerp(
                          baseGradient.colors.first,
                          Colors.white,
                          0.03 * flickerIntensity * t) ??
                      baseGradient.colors.first,
                  Color.lerp(
                          baseGradient.colors.last,
                          Colors.black,
                          0.04 * flickerIntensity * (2 - t)) ??
                      baseGradient.colors.last,
                ],
              )
            : baseGradient;

        final shadow = (baseShadow == null || baseShadow.isEmpty || !hasFlicker)
            ? baseShadow
            : baseShadow
                .map(
                  (s) => BoxShadow(
                    color: s.color
                        .withOpacity(s.color.opacity * flickerOpacity),
                    blurRadius: s.blurRadius * t,
                    offset: s.offset,
                    spreadRadius: s.spreadRadius,
                  ),
                )
                .toList();

        return Opacity(
          opacity: isEnabled ? 1 : 0.5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: borderRadius,
              boxShadow: shadow,
            ),
            child: Semantics(
              button: true,
              enabled: isEnabled,
              label: widget.semanticsLabel,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: borderRadius,
                  splashColor: isEnabled ? overlay : Colors.transparent,
                  highlightColor: isEnabled ? overlay : Colors.transparent,
                  onTap: isEnabled ? widget.onPressed : null,
                  child: Container(
                    height: height,
                    padding: padding,
                    alignment: Alignment.center,
                    child: DefaultTextStyle.merge(
                      style: (textStyle ??
                              const TextStyle(fontWeight: FontWeight.bold))
                          .copyWith(color: onBrand),
                      child: IconTheme(
                        data: IconThemeData(color: onBrand),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
