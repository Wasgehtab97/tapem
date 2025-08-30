import 'package:flutter/material.dart';

/// Theme extension exposing contrast-safe foreground colours for brand tokens.
class BrandOnColors extends ThemeExtension<BrandOnColors> {
  final Color onPrimary;
  final Color onSecondary;
  final Color onGradient;
  final Color onCta;

  const BrandOnColors({
    required this.onPrimary,
    required this.onSecondary,
    required this.onGradient,
    required this.onCta,
  });

  @override
  BrandOnColors copyWith({
    Color? onPrimary,
    Color? onSecondary,
    Color? onGradient,
    Color? onCta,
  }) {
    return BrandOnColors(
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      onGradient: onGradient ?? this.onGradient,
      onCta: onCta ?? this.onCta,
    );
  }

  @override
  BrandOnColors lerp(ThemeExtension<BrandOnColors>? other, double t) {
    if (other is! BrandOnColors) return this;
    return BrandOnColors(
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t) ?? onPrimary,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t) ?? onSecondary,
      onGradient: Color.lerp(onGradient, other.onGradient, t) ?? onGradient,
      onCta: Color.lerp(onCta, other.onCta, t) ?? onCta,
    );
  }
}
