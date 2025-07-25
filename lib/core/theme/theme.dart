import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

/// Enthält alle Farben und zentrale Theme-Definitionen für die App.
class AppTheme {
  static const Color primaryBlue  = AppColors.accentBlue;
  static const Color accentBlue   = AppColors.accentOrange;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen  = Color(0xFF66BB6A);

  static const Color neutralPrimary = Color(0xFF424242);
  static const Color neutralAccent  = Color(0xFF616161);

  static const Color darkBackground = AppColors.background;
  static const Color surfaceBlack   = AppColors.surface;

  static const Color onPrimary       = AppColors.textPrimary;
  static const Color onSurface       = AppColors.textSecondary;
  static const Color onSurface38     = Colors.white38;
  static const Color onSurface54     = Colors.white54;

  /// Zentrales Dark-Theme (Blau)
  static final ThemeData darkTheme = _buildTheme(
    primary: primaryBlue,
    secondary: accentBlue,
  );

  /// Zentrales Dark-Theme (Grün)
  static final ThemeData greenDarkTheme = _buildTheme(
    primary: primaryGreen,
    secondary: accentGreen,
  );

  /// Neutrales Dark-Theme (Grau) für Auth-Screens
  static final ThemeData neutralTheme = _buildTheme(
    primary: neutralPrimary,
    secondary: neutralAccent,
  );

  /// Erstellt ein Theme mit beliebigen Farben.
  static ThemeData customTheme({
    required Color primary,
    required Color secondary,
  }) => _buildTheme(primary: primary, secondary: secondary);

  /// Baut ein ThemeData mit angegebenen Primär- und Sekundärfarben.
  static ThemeData _buildTheme({
    required Color primary,
    required Color secondary,
  }) {
    final base = ThemeData(brightness: Brightness.dark);
    final scheme = ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      background: darkBackground,
      surface: surfaceBlack,
      onPrimary: onPrimary,
      onSurface: onSurface,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: darkBackground,
      canvasColor: surfaceBlack,
      hintColor: onSurface,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceBlack,
        elevation: 2,
        iconTheme: IconThemeData(color: onPrimary),
        titleTextStyle: TextStyle(
          color: onPrimary,
          fontSize: AppFontSizes.headline,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: onPrimary,
          textStyle: TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onPrimary,
          side: BorderSide(color: onSurface54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondary,
          textStyle: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: onPrimary,
        elevation: 4,
        sizeConstraints: BoxConstraints.tightFor(width: 48, height: 48),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceBlack,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: onSurface38),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: secondary),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        hintStyle: TextStyle(color: onSurface38),
        labelStyle: TextStyle(color: onSurface54),
      ),
      cardTheme: CardTheme(
        color: surfaceBlack,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceBlack,
        selectedItemColor: secondary,
        unselectedItemColor: onSurface54,
        showUnselectedLabels: true,
      ),
      tabBarTheme: TabBarTheme(
        indicatorColor: secondary,
        labelColor: onPrimary,
        unselectedLabelColor: onSurface54,
      ),
      textTheme: TextTheme(
        titleLarge: GoogleFonts.inter(
          color: onPrimary,
          fontSize: AppFontSizes.headline,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: GoogleFonts.inter(
          color: onSurface,
          fontSize: AppFontSizes.title,
        ),
        bodyMedium: GoogleFonts.inter(
          color: onSurface,
          fontSize: AppFontSizes.body,
        ),
        labelLarge: GoogleFonts.inter(
          color: onPrimary,
          fontSize: AppFontSizes.body,
          fontWeight: FontWeight.w600,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: MaterialStateProperty.all(secondary.withOpacity(0.7)),
        radius: const Radius.circular(AppRadius.button),
        thickness: MaterialStateProperty.all(6),
      ),
      dividerColor: onSurface38,
      dialogBackgroundColor: surfaceBlack,
    );
  }
}
