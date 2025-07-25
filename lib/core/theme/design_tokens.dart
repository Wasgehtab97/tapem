import 'package:flutter/material.dart';

/// Central design tokens for colors, spacing and typography.
class AppColors {
  static const background = Color(0xFF121212); // deep anthracite
  static const surface = Color(0xFF1E1E1E);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFCCCCCC);
  static const accentBlue = Color(0xFF448AFF);
  static const accentOrange = Color(0xFFFF7043);
}

class AppSpacing {
  static const xs = 8.0;
  static const sm = 16.0;
  static const md = 24.0;
}

class AppRadius {
  static const card = 16.0;
  static const button = 12.0;
}

class AppFontSizes {
  static const headline = 20.0;
  static const title = 16.0;
  static const body = 14.0;
}

class AppGradients {
  static const primary = LinearGradient(
    colors: [AppColors.accentBlue, AppColors.accentOrange],
  );
}

class AppDurations {
  static const short = Duration(milliseconds: 300);
}
