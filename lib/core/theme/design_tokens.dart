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

/// Supporting palettes for built-in manual brand themes.
class PresetBrandColors {
  PresetBrandColors._();

  /// Cool azure palette with a deep sapphire accent.
  static const Color azurePrimary = Color(0xFF1E88E5);
  static const Color azureSecondary = Color(0xFF0D47A1);
  static const Color azureGradientStart = Color(0xFF42A5F5);
  static const Color azureGradientEnd = Color(0xFF0D47A1);
  static const Color azureFocus = Color(0xFF64B5F6);

  /// Warm amber/orange gradient reminiscent of sunsets.
  static const Color amberPrimary = Color(0xFFFF6F61);
  static const Color amberSecondary = Color(0xFFFFA726);
  static const Color amberGradientStart = Color(0xFFFF8A65);
  static const Color amberGradientEnd = Color(0xFFFFB74D);
  static const Color amberFocus = Color(0xFFFF7043);

  /// Lush forest greens.
  static const Color forestPrimary = Color(0xFF2E7D32);
  static const Color forestSecondary = Color(0xFF66BB6A);
  static const Color forestGradientStart = Color(0xFF1B5E20);
  static const Color forestGradientEnd = Color(0xFF66BB6A);
  static const Color forestFocus = Color(0xFF43A047);

  /// Regal purples.
  static const Color royalPrimary = Color(0xFF8E24AA);
  static const Color royalSecondary = Color(0xFFBA68C8);
  static const Color royalGradientStart = Color(0xFF6A1B9A);
  static const Color royalGradientEnd = Color(0xFFCE93D8);
  static const Color royalFocus = Color(0xFFAB47BC);

  /// High-energy neon lime palette.
  static const Color neonPrimary = Color(0xFFAEEA00);
  static const Color neonSecondary = Color(0xFF64DD17);
  static const Color neonGradientStart = Color(0xFFC6FF00);
  static const Color neonGradientEnd = Color(0xFF64DD17);
  static const Color neonFocus = Color(0xFF76FF03);

  /// Copper and bronze metals.
  static const Color copperPrimary = Color(0xFF8D5524);
  static const Color copperSecondary = Color(0xFFD8903B);
  static const Color copperGradientStart = Color(0xFFB66A2E);
  static const Color copperGradientEnd = Color(0xFFF4A259);
  static const Color copperFocus = Color(0xFFF4A259);

  /// Bright arctic blues.
  static const Color arcticPrimary = Color(0xFF4FC3F7);
  static const Color arcticSecondary = Color(0xFF81D4FA);
  static const Color arcticGradientStart = Color(0xFF81D4FA);
  static const Color arcticGradientEnd = Color(0xFFE1F5FE);
  static const Color arcticFocus = Color(0xFF29B6F6);

  /// Fiery ember palette.
  static const Color emberPrimary = Color(0xFFFF7043);
  static const Color emberSecondary = Color(0xFFD84315);
  static const Color emberGradientStart = Color(0xFFFF8A65);
  static const Color emberGradientEnd = Color(0xFFD84315);
  static const Color emberFocus = Color(0xFFFF5722);

  /// Neon cyber grape palette.
  static const Color cyberPrimary = Color(0xFF7E57C2);
  static const Color cyberSecondary = Color(0xFF311B92);
  static const Color cyberGradientStart = Color(0xFF9575CD);
  static const Color cyberGradientEnd = Color(0xFF4527A0);
  static const Color cyberFocus = Color(0xFFB39DDB);

  /// Vibrant citrus yellows and oranges.
  static const Color citrusPrimary = Color(0xFFFFD54F);
  static const Color citrusSecondary = Color(0xFFFFB300);
  static const Color citrusGradientStart = Color(0xFFFFF176);
  static const Color citrusGradientEnd = Color(0xFFFFB74D);
  static const Color citrusFocus = Color(0xFFFFC107);

  /// Soft anime-inspired sakura & sky palette.
  static const Color animePrimary = Color(0xFFFF8AC9); // sakura pink
  static const Color animeSecondary = Color(0xFF80D8FF); // sky blue
  static const Color animeGradientStart = Color(0xFFFFC1E3); // soft sakura
  static const Color animeGradientEnd = Color(0xFF80D8FF); // clear sky
  static const Color animeFocus = Color(0xFFFFE4F3); // light cherry blossom glow

  /// Fire Nation-inspired reds and golds.
  static const Color flamePrimary = Color(0xFFD32F2F); // deep crimson
  static const Color flameSecondary = Color(0xFFFFB300); // royal gold
  static const Color flameGradientStart = Color(0xFF8B0000); // dark fire
  static const Color flameGradientEnd = Color(0xFFFF6F00); // glowing ember
  static const Color flameFocus = Color(0xFFFFE08A); // soft golden aura

  /// Water Tribe-inspired deep ocean blues.
  static const Color waterPrimary = Color(0xFF0D47A1);
  static const Color waterSecondary = Color(0xFF26C6DA);
  static const Color waterGradientStart = Color(0xFF0B3954);
  static const Color waterGradientEnd = Color(0xFF26C6DA);
  static const Color waterFocus = Color(0xFF81D4FA);

  /// Air Nomads-inspired warm sky hues.
  static const Color airPrimary = Color(0xFFFFB74D);
  static const Color airSecondary = Color(0xFFFFF59D);
  static const Color airGradientStart = Color(0xFFFFCC80);
  static const Color airGradientEnd = Color(0xFFFFF9C4);
  static const Color airFocus = Color(0xFFFFF9C4);

  /// Earth Kingdom-inspired deep greens.
  static const Color earthPrimary = Color(0xFF33691E);
  static const Color earthSecondary = Color(0xFF8BC34A);
  static const Color earthGradientStart = Color(0xFF1B5E20);
  static const Color earthGradientEnd = Color(0xFFA5D6A7);
  static const Color earthFocus = Color(0xFFC5E1A5);
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
