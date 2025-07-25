import 'package:flutter/material.dart';

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

/// Standard spacing values based on an 8px grid.
class AppSpacing {
  static const double xs = 8.0;
  static const double sm = 16.0;
  static const double md = 24.0;
  static const double lg = 32.0;
}

/// Corner radii definitions.
class AppRadius {
  static const double card = 16.0;
  static const double button = 12.0;
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
}

/// Animation durations.
class AppDurations {
  static const Duration short = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 400);
}
