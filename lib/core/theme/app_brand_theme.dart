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
      outline: gradient.colors.first,
    );
  }

  /// Magenta/violet CTA preset used for `gym_01`.
  static AppBrandTheme magenta() {
    final gradient = AppGradients.brandGradient;
    final lums = gradient.colors.map((c) => c.computeLuminance());
    final lum = lums.reduce((a, b) => a + b) / gradient.colors.length;
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
      outline: gradient.colors.first,
    );
  }
}
