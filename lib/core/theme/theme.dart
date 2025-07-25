import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

/// Provides the dark themes for the Tap’em app based on the new design tokens.
///
/// The themes defined here build upon `ThemeData.dark()` and override colours
/// and typography to create high-contrast, minimalistic UIs. Each theme
/// variant pairs different primary and secondary accents – e.g. mint +
/// turquoise – while maintaining a consistent base.
class AppTheme {
  /// Builds a ThemeData with the given primary and secondary colours.
  static ThemeData _buildTheme({
    required Color primary,
    required Color secondary,
  }) {
    final base = ThemeData(brightness: Brightness.dark);
    final scheme = ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      background: AppColors.background,
      surface: AppColors.surface,
      onPrimary: AppColors.textPrimary,
      onSurface: AppColors.textSecondary,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
      cardColor: AppColors.surface,
      hintColor: AppColors.textSecondary,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: secondary,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: true,
      ),
      textTheme: TextTheme(
        // Large display numbers
        displayLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: AppFontSizes.kpi,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: AppFontSizes.headline,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: AppFontSizes.title,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: AppFontSizes.body,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: secondary),
        ),
        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: AppColors.textPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondary,
          side: BorderSide(color: secondary.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
    );
  }

  /// Builds a custom theme from arbitrary colors.
  static ThemeData customTheme({
    required Color primary,
    required Color secondary,
  }) => _buildTheme(primary: primary, secondary: secondary);

  /// The default dark theme using mint as primary and turquoise as secondary.
  static final ThemeData mintDarkTheme = _buildTheme(
    primary: AppColors.accentMint,
    secondary: AppColors.accentTurquoise,
  );

  /// An alternate theme that highlights amber accents (e.g. for warning states).
  static final ThemeData amberDarkTheme = _buildTheme(
    primary: AppColors.accentAmber,
    secondary: AppColors.accentTurquoise,
  );

  /// A neutral dark theme without strong branding accents.
  static final ThemeData neutralTheme = _buildTheme(
    primary: AppColors.accentTurquoise,
    secondary: AppColors.accentTurquoise,
  );
}
