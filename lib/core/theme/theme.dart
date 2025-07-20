import 'package:flutter/material.dart';

/// Enthält alle Farben und zentrale Theme-Definitionen für die App.
class AppTheme {
  // Blau-Theme Hauptfarben
  static const Color primaryBlue     = Color(0xFF0D47A1);
  static const Color accentBlue      = Color(0xFF2979FF);

  // Grün-Theme Hauptfarben
  static const Color primaryGreen    = Color(0xFF2E7D32);
  static const Color accentGreen     = Color(0xFF66BB6A);

  // Neutrale Farben für Auth
  static const Color neutralPrimary  = Color(0xFF424242);
  static const Color neutralAccent   = Color(0xFF616161);

  // Gemeinsame Farben
  static const Color darkBackground  = Color(0xFF121212);
  static const Color surfaceBlack    = Color(0xFF1E1E1E);
  static const Color onPrimary       = Colors.white;
  static const Color onSurface       = Colors.white70;
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
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: onPrimary,
          textStyle: TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onPrimary,
          side: BorderSide(color: onSurface54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: onSurface38),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: secondary),
          borderRadius: BorderRadius.circular(8),
        ),
        hintStyle: TextStyle(color: onSurface38),
        labelStyle: TextStyle(color: onSurface54),
      ),
      cardTheme: CardTheme(
        color: surfaceBlack,
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: onPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: onSurface, fontSize: 16),
        bodyMedium: TextStyle(color: onSurface, fontSize: 14),
        labelLarge: TextStyle(color: onPrimary, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: MaterialStateProperty.all(secondary.withOpacity(0.7)),
        radius: Radius.circular(8),
        thickness: MaterialStateProperty.all(6),
      ),
      dividerColor: onSurface38,
      dialogBackgroundColor: surfaceBlack,
    );
  }
}
