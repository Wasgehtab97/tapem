import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Theme extension that exposes the global brand tokens such as
/// gradient, radii, shadows and foreground colours.
class AppBrandTheme extends ThemeExtension<AppBrandTheme> {
  final LinearGradient gradient;
  final BorderRadiusGeometry radius;
  final List<BoxShadow> shadow;
  final Color pressedOverlay;
  final Color focusRing;
  final TextStyle textStyle;
  final double height;
  final EdgeInsetsGeometry padding;
  final double luminanceRef;
  final Color onBrand;
  final Color outline;

  /// Gradient used for brand outlines.
  final LinearGradient outlineGradient;

  /// Fallback solid colour for high contrast modes.
  final Color outlineColorFallback;

  /// Width of the outline stroke.
  final double outlineWidth;

  /// Corner radius for outlined surfaces.
  final BorderRadiusGeometry outlineRadius;

  /// Glow or shadow applied when an outlined element is selected.
  final List<BoxShadow> outlineShadow;

  /// Opacity applied when an outlined element is disabled.
  final double outlineDisabledOpacity;

  const AppBrandTheme({
    required this.gradient,
    required this.radius,
    required this.shadow,
    required this.pressedOverlay,
    required this.focusRing,
    required this.textStyle,
    required this.height,
    required this.padding,
    required this.luminanceRef,
    required this.onBrand,
    required this.outline,
    required this.outlineGradient,
    required this.outlineColorFallback,
    required this.outlineWidth,
    required this.outlineRadius,
    required this.outlineShadow,
    required this.outlineDisabledOpacity,
  });

  @override
  AppBrandTheme copyWith({
    LinearGradient? gradient,
    BorderRadiusGeometry? radius,
    List<BoxShadow>? shadow,
    Color? pressedOverlay,
    Color? focusRing,
    TextStyle? textStyle,
    double? height,
    EdgeInsetsGeometry? padding,
    double? luminanceRef,
    Color? onBrand,
    Color? outline,
    LinearGradient? outlineGradient,
    Color? outlineColorFallback,
    double? outlineWidth,
    BorderRadiusGeometry? outlineRadius,
    List<BoxShadow>? outlineShadow,
    double? outlineDisabledOpacity,
  }) {
    return AppBrandTheme(
      gradient: gradient ?? this.gradient,
      radius: radius ?? this.radius,
      shadow: shadow ?? this.shadow,
      pressedOverlay: pressedOverlay ?? this.pressedOverlay,
      focusRing: focusRing ?? this.focusRing,
      textStyle: textStyle ?? this.textStyle,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      luminanceRef: luminanceRef ?? this.luminanceRef,
      onBrand: onBrand ?? this.onBrand,
      outline: outline ?? this.outline,
      outlineGradient: outlineGradient ?? this.outlineGradient,
      outlineColorFallback: outlineColorFallback ?? this.outlineColorFallback,
      outlineWidth: outlineWidth ?? this.outlineWidth,
      outlineRadius: outlineRadius ?? this.outlineRadius,
      outlineShadow: outlineShadow ?? this.outlineShadow,
      outlineDisabledOpacity:
          outlineDisabledOpacity ?? this.outlineDisabledOpacity,
    );
  }

  @override
  AppBrandTheme lerp(ThemeExtension<AppBrandTheme>? other, double t) {
    if (other is! AppBrandTheme) return this;
    return AppBrandTheme(
      gradient: LinearGradient(
        begin: gradient.begin,
        end: gradient.end,
        colors: List.generate(
          gradient.colors.length,
          (i) => Color.lerp(gradient.colors[i], other.gradient.colors[i], t)!,
        ),
      ),
      radius: BorderRadius.lerp(radius as BorderRadius?, other.radius as BorderRadius?, t) ?? radius,
      shadow: _lerpShadowList(shadow, other.shadow, t),
      pressedOverlay: Color.lerp(pressedOverlay, other.pressedOverlay, t) ?? pressedOverlay,
      focusRing: Color.lerp(focusRing, other.focusRing, t) ?? focusRing,
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t) ?? textStyle,
      height: lerpDouble(height, other.height, t) ?? height,
      padding: EdgeInsets.lerp(padding as EdgeInsets?, other.padding as EdgeInsets?, t) ?? padding,
      luminanceRef: lerpDouble(luminanceRef, other.luminanceRef, t) ?? luminanceRef,
      onBrand: Color.lerp(onBrand, other.onBrand, t) ?? onBrand,
      outline: Color.lerp(outline, other.outline, t) ?? outline,
      outlineGradient: LinearGradient(
        begin: outlineGradient.begin,
        end: outlineGradient.end,
        colors: List.generate(
          outlineGradient.colors.length,
          (i) => Color.lerp(
            outlineGradient.colors[i],
            other.outlineGradient.colors[i],
            t,
          )!,
        ),
      ),
      outlineColorFallback:
          Color.lerp(outlineColorFallback, other.outlineColorFallback, t) ??
              outlineColorFallback,
      outlineWidth: lerpDouble(outlineWidth, other.outlineWidth, t) ??
          outlineWidth,
      outlineRadius: BorderRadius.lerp(
            outlineRadius as BorderRadius?,
            other.outlineRadius as BorderRadius?,
            t,
          ) ??
          outlineRadius,
      outlineShadow: _lerpShadowList(outlineShadow, other.outlineShadow, t),
      outlineDisabledOpacity: lerpDouble(
            outlineDisabledOpacity,
            other.outlineDisabledOpacity,
            t,
          ) ??
          outlineDisabledOpacity,
    );
  }

  static List<BoxShadow> _lerpShadowList(List<BoxShadow> a, List<BoxShadow> b, double t) {
    final count = math.max(a.length, b.length);
    return List.generate(count, (i) {
      final sa = i < a.length ? a[i] : const BoxShadow();
      final sb = i < b.length ? b[i] : const BoxShadow();
      return BoxShadow.lerp(sa, sb, t)!;
    });
  }

  /// Default CTA theme using the global AppGradients.brandGradient.
  static AppBrandTheme defaultTheme() {
    final gradient = AppGradients.brandGradient;
    final lums = gradient.colors.map((c) => c.computeLuminance());
    final lum = lums.reduce((a, b) => a + b) / gradient.colors.length;
    final outlineColor = gradient.colors.first;
    return AppBrandTheme(
      gradient: gradient,
      radius: BorderRadius.circular(AppRadius.button),
      shadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))],
      pressedOverlay: Colors.black26,
      focusRing: AppColors.accentTurquoise,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      luminanceRef: lum,
      onBrand: AppColors.textPrimary,
      outline: outlineColor,
      outlineGradient: gradient,
      outlineColorFallback: outlineColor,
      outlineWidth: 2,
      outlineRadius: BorderRadius.circular(AppRadius.card),
      outlineShadow: [
        BoxShadow(color: outlineColor.withOpacity(0.5), blurRadius: 8),
      ],
      outlineDisabledOpacity: 0.4,
    );
  }

  /// Magenta/violet CTA preset used for `lifthouse_koblenz`.
  static AppBrandTheme magenta() {
    final gradient = AppGradients.brandGradient;
    final lums = gradient.colors.map((c) => c.computeLuminance());
    final lum = lums.reduce((a, b) => a + b) / gradient.colors.length;
    final outlineColor = gradient.colors.first;
    return AppBrandTheme(
      gradient: gradient,
      radius: BorderRadius.circular(AppRadius.button),
      shadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))],
      pressedOverlay: MagentaColors.pressedTint.withOpacity(0.3),
      focusRing: MagentaColors.focus,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      luminanceRef: lum,
      onBrand: MagentaColors.textPrimary,
      outline: outlineColor,
      outlineGradient: gradient,
      outlineColorFallback: outlineColor,
      outlineWidth: 2,
      outlineRadius: BorderRadius.circular(AppRadius.card),
      outlineShadow: [
        BoxShadow(color: gradient.colors.last.withOpacity(0.5), blurRadius: 8),
      ],
      outlineDisabledOpacity: 0.4,
    );
  }

  /// Red/orange CTA preset used for "Club Aktiv".
  static AppBrandTheme clubAktiv() {
    final gradient = AppGradients.brandGradient;
    final lums = gradient.colors.map((c) => c.computeLuminance());
    final lum = lums.reduce((a, b) => a + b) / gradient.colors.length;
    final outlineColor = gradient.colors.first;
    return AppBrandTheme(
      gradient: gradient,
      radius: BorderRadius.circular(AppRadius.button),
      shadow:
          const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))],
      pressedOverlay: ClubAktivColors.pressedTint.withOpacity(0.3),
      focusRing: ClubAktivColors.focus,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      luminanceRef: lum,
      onBrand: ClubAktivColors.textPrimary,
      outline: outlineColor,
      outlineGradient: gradient,
      outlineColorFallback: outlineColor,
      outlineWidth: 2,
      outlineRadius: BorderRadius.circular(AppRadius.card),
      outlineShadow: [
        BoxShadow(color: gradient.colors.last.withOpacity(0.5), blurRadius: 8),
      ],
      outlineDisabledOpacity: 0.4,
    );
  }
}
