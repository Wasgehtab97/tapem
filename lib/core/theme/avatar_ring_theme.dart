import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'design_tokens.dart';

@immutable
class AvatarRingTheme extends ThemeExtension<AvatarRingTheme> {
  final Color trackColor;
  final LinearGradient progressGradient;
  final double strokeWidth;

  const AvatarRingTheme({
    required this.trackColor,
    required this.progressGradient,
    required this.strokeWidth,
  });

  @override
  AvatarRingTheme copyWith({
    Color? trackColor,
    LinearGradient? progressGradient,
    double? strokeWidth,
  }) {
    return AvatarRingTheme(
      trackColor: trackColor ?? this.trackColor,
      progressGradient: progressGradient ?? this.progressGradient,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }

  @override
  AvatarRingTheme lerp(AvatarRingTheme? other, double t) {
    if (other == null) return this;
    return AvatarRingTheme(
      trackColor: Color.lerp(trackColor, other.trackColor, t) ?? trackColor,
      progressGradient: LinearGradient.lerp(progressGradient, other.progressGradient, t) ?? progressGradient,
      strokeWidth: lerpDouble(strokeWidth, other.strokeWidth, t)!,
    );
  }

  static const AvatarRingTheme fallback = AvatarRingTheme(
    trackColor: AppColors.surface,
    progressGradient: AppGradients.progress,
    strokeWidth: 4.0,
  );
}
