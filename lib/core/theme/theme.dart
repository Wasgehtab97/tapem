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
    Color background = AppColors.background,
    Color surface = AppColors.surface,
    Color? surface2,
    Color textPrimary = AppColors.textPrimary,
    Color textSecondary = AppColors.textSecondary,
    Color focus = AppColors.accentTurquoise,
    Color? buttonColor,
  }) {
    final base = ThemeData(brightness: Brightness.dark);
    final scheme = ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      background: background,
      surface: surface,
      onPrimary: textPrimary,
      onSurface: textSecondary,
      outline: focus,
    );
    final btnColor = buttonColor ?? secondary;
    final s2 = surface2 ?? surface;
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: s2,
      cardColor: surface,
      hintColor: textSecondary,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: secondary,
        unselectedItemColor: textSecondary,
        showUnselectedLabels: true,
      ),
      textTheme: TextTheme(
        // Large display numbers
        displayLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: AppFontSizes.kpi,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: AppFontSizes.headline,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.inter(
          color: textSecondary,
          fontSize: AppFontSizes.title,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textSecondary,
          fontSize: AppFontSizes.body,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(
            color: textSecondary.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: focus),
        ),
        hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: textPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: btnColor,
          side: BorderSide(color: btnColor.withOpacity(0.5)),
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
    buttonColor: AppColors.accentTurquoise,
  );

  /// An alternate theme that highlights amber accents (e.g. for warning states).
  static final ThemeData amberDarkTheme = _buildTheme(
    primary: AppColors.accentAmber,
    secondary: AppColors.accentTurquoise,
    buttonColor: AppColors.accentTurquoise,
  );

  /// A neutral dark theme without strong branding accents.
  static final ThemeData neutralTheme = _buildTheme(
    primary: AppColors.accentTurquoise,
    secondary: AppColors.accentTurquoise,
    buttonColor: AppColors.accentTurquoise,
  );

  /// Magenta dark theme for special gym branding.
  static final ThemeData magentaDarkTheme = _buildTheme(
    primary: MagentaColors.primary600,
    secondary: MagentaColors.secondary,
    background: MagentaColors.bg,
    surface: MagentaColors.surface1,
    surface2: MagentaColors.surface2,
    textPrimary: MagentaColors.textPrimary,
    textSecondary: MagentaColors.textSecondary,
    focus: MagentaColors.focus,
    buttonColor: MagentaColors.primary600,
  );

  /// Red/orange dark theme for the "Club Aktiv" gym.
  static final ThemeData clubAktivDarkTheme = _buildTheme(
    primary: ClubAktivColors.primary600,
    secondary: ClubAktivColors.secondary,
    background: ClubAktivColors.bg,
    surface: ClubAktivColors.surface1,
    surface2: ClubAktivColors.surface2,
    textPrimary: ClubAktivColors.textPrimary,
    textSecondary: ClubAktivColors.textSecondary,
    focus: ClubAktivColors.focus,
    buttonColor: ClubAktivColors.primary600,
  );
}
