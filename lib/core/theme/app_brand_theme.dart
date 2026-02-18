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

  /// Optional surface colour for components that sit inside a brand outline
  /// (e.g. session cards). When null, widgets fall back to the theme surface.
  final Color? surfaceColor;

  /// Intensity of animated flicker on brand-driven widgets such as
  /// [BrandPrimaryButton]. `0` disables any animation.
  final double flickerIntensity;

  /// Whether the current brand theme is the "flame" preset.
  ///
  /// Used by widgets that opt into flame-specific visuals (e.g. `FlameBadge`).
  final bool isFlame;

  /// Whether the current brand theme is the "midnight gold" preset.
  final bool isMidnight;

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
    this.surfaceColor,
    this.flickerIntensity = 0.0,
    this.isFlame = false,
    this.isMidnight = false,
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
    Color? surfaceColor,
    double? flickerIntensity,
    bool? isFlame,
    bool? isMidnight,
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
      surfaceColor: surfaceColor ?? this.surfaceColor,
      flickerIntensity: flickerIntensity ?? this.flickerIntensity,
      isFlame: isFlame ?? this.isFlame,
      isMidnight: isMidnight ?? this.isMidnight,
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
      surfaceColor:
          Color.lerp(surfaceColor, other.surfaceColor, t) ?? surfaceColor,
      flickerIntensity:
          lerpDouble(flickerIntensity, other.flickerIntensity, t) ??
              flickerIntensity,
      isFlame: t < 0.5 ? isFlame : other.isFlame,
      isMidnight: t < 0.5 ? isMidnight : other.isMidnight,
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
      flickerIntensity: 0.0,
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
      flickerIntensity: 0.0,
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
      flickerIntensity: 0.0,
    );
  }

  /// Cyberpunk neon CTA preset with stronger glow and sharper outlines.
  static AppBrandTheme cyberpunk() {
    final gradient = AppGradients.brandGradient;
    final lums = gradient.colors.map((c) => c.computeLuminance());
    final lum = lums.reduce((a, b) => a + b) / gradient.colors.length;
    final outlineColor = gradient.colors.first;
    // Tinted surface for cards and outlined components in the cyberpunk theme.
    final surface = Color.lerp(
      const Color(0xFF050813),
      gradient.colors.first,
      0.12,
    )!;
    return AppBrandTheme(
      gradient: gradient,
      // Etwas stärker gerundete Ecken für futuristischen Look.
      radius: BorderRadius.circular(AppRadius.button * 1.3),
      shadow: [
        // Innerer, konzentrierter Glow nahe am Element.
        BoxShadow(
          color: gradient.colors.first.withOpacity(0.7),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
        // Weicher, weiter gefächerter Neon-Glow für mehr Tiefe.
        BoxShadow(
          color: gradient.colors.last.withOpacity(0.45),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
      // Farbiges Overlay statt neutralem Weiß für einen „holographischen“ Tap-State.
      pressedOverlay: gradient.colors.first.withOpacity(0.14),
      focusRing: gradient.colors.first.withOpacity(0.9),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md + 4),
      luminanceRef: lum,
      onBrand: Colors.black,
      outline: outlineColor,
      outlineGradient: gradient,
      outlineColorFallback: outlineColor,
      outlineWidth: 2.6,
      outlineRadius: BorderRadius.circular(AppRadius.cardLg),
      outlineShadow: [
        BoxShadow(
          color: gradient.colors.first.withOpacity(0.7),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: gradient.colors.last.withOpacity(0.5),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
      outlineDisabledOpacity: 0.35,
      surfaceColor: surface,
      flickerIntensity: 0.25,
    );
  }

  /// Anime-inspired CTA preset with softer glow and pastel outlines.
  static AppBrandTheme anime() {
    final gradient = AppGradients.brandGradient;
    final lums = gradient.colors.map((c) => c.computeLuminance());
    final lum = lums.reduce((a, b) => a + b) / gradient.colors.length;
    final outlineColor = gradient.colors.first;
    // Soft, slightly lifted surface with a hint of sakura.
    final surface = Color.lerp(
      const Color(0xFF090813),
      gradient.colors.first,
      0.1,
    )!;
    return AppBrandTheme(
      gradient: gradient,
      radius: BorderRadius.circular(AppRadius.button * 1.2),
      shadow: [
        BoxShadow(
          color: gradient.colors.first.withOpacity(0.45),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: gradient.colors.last.withOpacity(0.3),
          blurRadius: 18,
          offset: const Offset(0, 12),
        ),
      ],
      pressedOverlay: gradient.colors.last.withOpacity(0.12),
      focusRing: gradient.colors.first.withOpacity(0.8),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      luminanceRef: lum,
      onBrand: Colors.black,
      outline: outlineColor,
      outlineGradient: gradient,
      outlineColorFallback: outlineColor,
      outlineWidth: 2.2,
      outlineRadius: BorderRadius.circular(AppRadius.cardLg),
      outlineShadow: [
        BoxShadow(
          color: gradient.colors.first.withOpacity(0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: gradient.colors.last.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 12),
        ),
      ],
      outlineDisabledOpacity: 0.4,
      surfaceColor: surface,
      flickerIntensity: 0.18,
    );
  }

  /// Flame CTA preset with hot embers and bright accents.
  static AppBrandTheme flame() {
    final gradient = AppGradients.brandGradient;
    final lums = gradient.colors.map((c) => c.computeLuminance());
    final lum = lums.reduce((a, b) => a + b) / gradient.colors.length;
    final outlineColor = gradient.colors.first;
    // Dark ember surface with a hint of glow.
    final surface = Color.lerp(
      const Color(0xFF120608),
      gradient.colors.first,
      0.14,
    )!;
    return AppBrandTheme(
      gradient: gradient,
      radius: BorderRadius.circular(AppRadius.button * 1.15),
      shadow: [
        BoxShadow(
          color: gradient.colors.first.withOpacity(0.65),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: gradient.colors.last.withOpacity(0.45),
          blurRadius: 26,
          offset: const Offset(0, 18),
        ),
      ],
      pressedOverlay: gradient.colors.first.withOpacity(0.18),
      focusRing: gradient.colors.last.withOpacity(0.95),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      luminanceRef: lum,
      onBrand: Colors.black,
      outline: outlineColor,
      outlineGradient: gradient,
      outlineColorFallback: outlineColor,
      outlineWidth: 2.4,
      outlineRadius: BorderRadius.circular(AppRadius.cardLg),
      outlineShadow: [
        BoxShadow(
          color: gradient.colors.first.withOpacity(0.7),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: gradient.colors.last.withOpacity(0.55),
          blurRadius: 28,
          offset: const Offset(0, 18),
        ),
      ],
      outlineDisabledOpacity: 0.38,
      surfaceColor: surface,
      flickerIntensity: 0.35,
      isFlame: true,
    );
  }

  /// Water Tribe CTA preset with fluid blue glows.
  static AppBrandTheme water() {
    final gradient = AppGradients.brandGradient;
    final lums = gradient.colors.map((c) => c.computeLuminance());
    final lum = lums.reduce((a, b) => a + b) / gradient.colors.length;
    final outlineColor = gradient.colors.first;
    final surface = Color.lerp(
      const Color(0xFF020915),
      gradient.colors.first,
      0.18,
    )!;
    return AppBrandTheme(
      gradient: gradient,
      radius: BorderRadius.circular(AppRadius.button * 1.2),
      shadow: [
        BoxShadow(
          color: gradient.colors.last.withOpacity(0.5),
          blurRadius: 20,
          offset: const Offset(0, 12),
        ),
      ],
      pressedOverlay: gradient.colors.last.withOpacity(0.16),
      focusRing: gradient.colors.first.withOpacity(0.85),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.45,
      ),
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      luminanceRef: lum,
      onBrand: Colors.white,
      outline: outlineColor,
      outlineGradient: gradient,
      outlineColorFallback: outlineColor,
      outlineWidth: 2.0,
      outlineRadius: BorderRadius.circular(AppRadius.cardLg),
      outlineShadow: [
        BoxShadow(
          color: gradient.colors.last.withOpacity(0.55),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
      outlineDisabledOpacity: 0.36,
      surfaceColor: surface,
      flickerIntensity: 0.22,
    );
  }

  /// Air Nomads CTA preset with light, airy surfaces.
  static AppBrandTheme air() {
    final gradient = AppGradients.brandGradient;
    final lums = gradient.colors.map((c) => c.computeLuminance());
    final lum = lums.reduce((a, b) => a + b) / gradient.colors.length;
    final outlineColor = gradient.colors.first;
    final surface = Color.lerp(
      const Color(0xFF080A12),
      gradient.colors.last,
      0.14,
    )!;
    return AppBrandTheme(
      gradient: gradient,
      radius: BorderRadius.circular(AppRadius.button * 1.4),
      shadow: [
        BoxShadow(
          color: gradient.colors.last.withOpacity(0.35),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
      pressedOverlay: gradient.colors.first.withOpacity(0.10),
      focusRing: gradient.colors.last.withOpacity(0.75),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      luminanceRef: lum,
      onBrand: Colors.black,
      outline: outlineColor,
      outlineGradient: gradient,
      outlineColorFallback: outlineColor,
      outlineWidth: 1.8,
      outlineRadius: BorderRadius.circular(AppRadius.cardLg),
      outlineShadow: [
        BoxShadow(
          color: gradient.colors.last.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 12),
        ),
      ],
      outlineDisabledOpacity: 0.32,
      surfaceColor: surface,
      flickerIntensity: 0.14,
    );
  }

  /// Earth Kingdom CTA preset with grounded, stable design.
  static AppBrandTheme earth() {
    final gradient = AppGradients.brandGradient;
    final lums = gradient.colors.map((c) => c.computeLuminance());
    final lum = lums.reduce((a, b) => a + b) / gradient.colors.length;
    final outlineColor = gradient.colors.first;
    final surface = Color.lerp(
      const Color(0xFF020B06),
      gradient.colors.first,
      0.12,
    )!;
    return AppBrandTheme(
      gradient: gradient,
      radius: BorderRadius.circular(AppRadius.button),
      shadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.6),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
      pressedOverlay: gradient.colors.first.withOpacity(0.12),
      focusRing: gradient.colors.last.withOpacity(0.9),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.35,
      ),
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      luminanceRef: lum,
      onBrand: Colors.white,
      outline: outlineColor,
      outlineGradient: gradient,
      outlineColorFallback: outlineColor,
      outlineWidth: 2.2,
      outlineRadius: BorderRadius.circular(AppRadius.card),
      outlineShadow: [
        BoxShadow(
          color: outlineColor.withOpacity(0.6),
          blurRadius: 14,
          offset: const Offset(0, 8),
        ),
      ],
      outlineDisabledOpacity: 0.3,
      surfaceColor: surface,
      flickerIntensity: 0.08,
    );
  }

  /// Midnight Gold CTA preset with premium liquid corners and golden glow.
  static AppBrandTheme midnight() {
    final gradient = AppGradients.brandGradient;
    final lums = gradient.colors.map((c) => c.computeLuminance());
    final lum = lums.reduce((a, b) => a + b) / gradient.colors.length;
    final outlineColor = gradient.colors.first;
    // Deep midnight surface with a hint of gold.
    final surface = Color.lerp(
      const Color(0xFF050505),
      gradient.colors.first,
      0.08,
    )!;
    return AppBrandTheme(
      gradient: gradient,
      // Premium "Liquid" Feel mit stärker abgerundeten Ecken.
      radius: BorderRadius.circular(AppRadius.button * 1.5),
      shadow: [
        BoxShadow(
          color: gradient.colors.first.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: const Color(0xFFFFD700).withOpacity(0.15),
          blurRadius: 30,
          offset: const Offset(0, 15),
        ),
      ],
      pressedOverlay: gradient.colors.first.withOpacity(0.15),
      focusRing: const Color(0xFFFFDF00),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md + 8),
      luminanceRef: lum,
      onBrand: Colors.black,
      outline: outlineColor,
      outlineGradient: gradient,
      outlineColorFallback: outlineColor,
      outlineWidth: 2.8,
      outlineRadius: BorderRadius.circular(AppRadius.cardLg * 1.2),
      outlineShadow: [
        BoxShadow(
          color: gradient.colors.first.withOpacity(0.5),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
      outlineDisabledOpacity: 0.3,
      surfaceColor: surface,
      flickerIntensity: 0.15,
      isMidnight: true,
    );
  }
}
