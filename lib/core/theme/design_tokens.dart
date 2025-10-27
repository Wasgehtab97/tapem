import 'package:flutter/material.dart';

double _averageLuminance(Iterable<Color> colors) {
  if (colors.isEmpty) return 0.0;
  final total = colors.fold<double>(0.0, (sum, c) => sum + c.computeLuminance());
  return total / colors.length;
}

double _clampLuminance(double value) => value.clamp(0.0, 1.0).toDouble();

Color _colorWithTargetLuminance(Color color, double targetLuminance) {
  final target = _clampLuminance(targetLuminance);
  final base = HSLColor.fromColor(color);
  final baseLightness = base.lightness;
  double low = -baseLightness;
  double high = 1.0 - baseLightness;
  var result = color;
  for (var i = 0; i < 16; i++) {
    final mid = (low + high) / 2;
    final candidateLightness = (baseLightness + mid).clamp(0.0, 1.0);
    final candidate = base.withLightness(candidateLightness).toColor();
    final lum = candidate.computeLuminance();
    result = candidate;
    if ((lum - target).abs() < 1e-4) {
      break;
    }
    if (lum > target) {
      high = mid;
    } else {
      low = mid;
    }
  }
  return result;
}

LinearGradient _gradientWithAverageLuminance(
  LinearGradient gradient,
  double targetLuminance,
) {
  final target = _clampLuminance(targetLuminance);
  double low = -1.0;
  double high = 1.0;
  var adjusted = gradient;
  for (var i = 0; i < 18; i++) {
    final mid = (low + high) / 2;
    final colors = gradient.colors
        .map((color) {
          final hsl = HSLColor.fromColor(color);
          final lightness = (hsl.lightness + mid).clamp(0.0, 1.0);
          return hsl.withLightness(lightness).toColor();
        })
        .toList(growable: false);
    final avg = _averageLuminance(colors);
    adjusted = LinearGradient(
      begin: gradient.begin,
      end: gradient.end,
      stops: gradient.stops,
      tileMode: gradient.tileMode,
      transform: gradient.transform,
      colors: colors,
    );
    if ((avg - target).abs() < 1e-4) {
      break;
    }
    if (avg > target) {
      high = mid;
    } else {
      low = mid;
    }
  }
  return adjusted;
}

/// New design tokens for the Tap’em dark theme.
///
/// This file defines the central colours, spacing values, radii and font sizes
/// for the refreshed UI.  It is intended to replace or extend the existing
/// `design_tokens.dart` file.  Colours are based on a high-contrast dark
/// palette with mint, turquoise and amber accents.  All values follow an
/// 8-pixel grid for consistency.
class AppColors {
  /// Main page background (deep anthracite).
  static const Color background = Color(0xFF121212);

  /// Card and panel background (dark grey).
  static const Color surface = Color(0xFF1E1E1E);

  /// Primary text colour (white).
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text colour (soft grey).
  static const Color textSecondary = Color(0xFFB0B0B0);

  /// Primary accent (mint green) used for highlights and progress values.
  static const Color accentMint = Color(0xFF00E676);

  /// Secondary accent (turquoise) used for medium values and neutral accents.
  static const Color accentTurquoise = Color(0xFF00BCD4);

  /// Warning accent (amber) used for warnings and low values.
  static const Color accentAmber = Color(0xFFFFC107);
}

/// Color palette for the magenta themed gym.
class MagentaColors {
  static const Color primary500 = Color(0xFFFF70D0);
  static const Color primary600 = Color(0xFFE845B6);
  static const Color secondary = Color(0xFF9B5DE5);
  static const Color focus = Color(0xFFFFA3E6);
  static const Color pressedTint = Color(0xFF6E2F7E);
  static const Color bg = Color(0xFF0B0F12);
  static const Color surface1 = Color(0xFF12161C);
  static const Color surface2 = Color(0xFF1A1F26);
  static const Color textPrimary = Color(0xFFF6F7FA);
  static const Color textSecondary = Color(0xFFC6CBD2);
  static const Color textTertiary = Color(0xFF8C93A1);
}

/// Helper functions for toning colours while preserving hue and saturation.
class Tone {
  /// Returns [color] with its lightness adjusted by [delta] using HSL.
  static Color color(Color color, double delta) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + delta).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Applies [delta] uniformly to all colours of [gradient].
  static LinearGradient gradient(LinearGradient gradient, double delta) {
    return LinearGradient(
      begin: gradient.begin,
      end: gradient.end,
      colors: gradient.colors.map((c) => color(c, delta)).toList(),
    );
  }
}

/// Dynamic tone tokens used for brightness normalisation in `lifthouse_koblenz`.
class MagentaTones {
  /// Reference luminance derived from the "Letzte Session" card.
  static double brightnessAnchor =
      MagentaColors.surface1.computeLuminance();

  /// Tone for cards and sheets.
  static Color surface1 = MagentaColors.surface1;

  /// Tone for inputs and key tiles.
  static Color surface2 = MagentaColors.surface2;

  /// Tone for control tiles and icon backgrounds.
  static Color control = MagentaColors.surface2;

  /// Re-computes tone values based on [gradient].
  static void normalizeFromGradient(LinearGradient gradient) {
    AppGradients.brandGradient =
        _gradientWithAverageLuminance(gradient, brightnessAnchor);

    surface1 = _colorWithTargetLuminance(MagentaColors.surface1, brightnessAnchor);
    surface2 = _colorWithTargetLuminance(
      MagentaColors.surface2,
      brightnessAnchor + 0.025,
    );
    control = _colorWithTargetLuminance(
      MagentaColors.surface2,
      brightnessAnchor + 0.01,
    );
  }
}

/// Color palette for the red/orange themed gym "Club Aktiv".
class ClubAktivColors {
  static const Color primary500 = Color(0xFFFF6A00);
  static const Color primary600 = Color(0xFFD32F2F);
  static const Color secondary = Color(0xFFF57C00);
  static const Color focus = Color(0xFFFF6A00);
  static const Color pressedTint = Color(0xFF7F1D1D);
  static const Color bg = Color(0xFF0B0F12);
  static const Color surface1 = Color(0xFF12161C);
  static const Color surface2 = Color(0xFF1A1F26);
  static const Color textPrimary = Color(0xFFF6F7FA);
  static const Color textSecondary = Color(0xFFC6CBD2);
  static const Color textTertiary = Color(0xFF8C93A1);
}

/// Dynamic tone tokens used for brightness normalisation in "Club Aktiv".
class ClubAktivTones {
  /// Reference luminance derived from the "Letzte Session" card.
  static double brightnessAnchor =
      ClubAktivColors.surface1.computeLuminance();

  /// Tone for cards and sheets.
  static Color surface1 = ClubAktivColors.surface1;

  /// Tone for inputs and key tiles.
  static Color surface2 = ClubAktivColors.surface2;

  /// Tone for control tiles and icon backgrounds.
  static Color control = ClubAktivColors.surface2;

  /// Re-computes tone values based on [gradient].
  static void normalizeFromGradient(LinearGradient gradient) {
    AppGradients.brandGradient =
        _gradientWithAverageLuminance(gradient, brightnessAnchor);

    surface1 = _colorWithTargetLuminance(ClubAktivColors.surface1, brightnessAnchor);
    surface2 = _colorWithTargetLuminance(
      ClubAktivColors.surface2,
      brightnessAnchor + 0.025,
    );
    control = _colorWithTargetLuminance(
      ClubAktivColors.surface2,
      brightnessAnchor + 0.01,
    );
  }
}

/// Standard spacing values based on an 8px grid.
class AppSpacing {
  static const double xs = 8.0;
  static const double sm = 16.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 40.0;
}

/// Corner radii definitions.
class AppRadius {
  static const double card = 16.0;
  static const double cardLg = 24.0;
  static const double button = 12.0;
  static const double chip = 20.0;
}

/// Typography sizes.  These values may be adjusted to taste but should stay
/// consistent throughout the app.
class AppFontSizes {
  static const double headline = 24.0;
  static const double title = 16.0;
  static const double body = 14.0;
  static const double kpi = 32.0; // used for large numeric readouts
}

/// Gradient definitions.
class AppGradients {
  /// Gradient used for progress rings and charts.  Transitions from mint to
  /// turquoise to amber.
  static const LinearGradient progress = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.accentMint,
      AppColors.accentTurquoise,
      AppColors.accentAmber,
    ],
  );

  /// Brand gradient used for primary UI elements.
  static LinearGradient brandGradient = const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.accentMint, AppColors.accentTurquoise],
  );

  /// Radial glow used for call-to-action highlights.
  static RadialGradient ctaGlow = RadialGradient(
    colors: [AppColors.accentMint.withOpacity(0.25), Colors.transparent],
    radius: 0.6,
  );

  static void setBrandGradient(Color start, Color end) {
    brandGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [start, end],
    );
  }

  static void setCtaGlow(Color color) {
    ctaGlow = RadialGradient(
      colors: [color.withOpacity(0.25), Colors.transparent],
      radius: 0.6,
    );
  }
}

/// Animation durations.
class AppDurations {
  static const Duration short = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 400);
}
