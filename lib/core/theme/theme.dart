// lib/core/theme/theme.dart

import 'package:flutter/material.dart';

/// Enthält alle Farben und zentrale Theme-Definitionen für die App.
class AppTheme {
  // Hauptfarben
  static const Color primaryBlue     = Color(0xFF0D47A1);
  static const Color accentBlue      = Color(0xFF2979FF);
  static const Color darkBackground  = Color(0xFF121212);
  static const Color surfaceBlack    = Color(0xFF1E1E1E);
  static const Color onPrimary       = Colors.white;
  static const Color onSurface       = Colors.white70;

  // Hilfs-Alpha-Werte für halbtransparente Farben
  static const Color onSurface38     = Colors.white38;
  static const Color onSurface54     = Colors.white54;

  /// Das zentrale ThemeData, das du in deiner MaterialApp nutzt.
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,

    // Statt primaryColor + accentColor setzen wir colorScheme
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: accentBlue,
      background: darkBackground,
      surface: surfaceBlack,
      onPrimary: onPrimary,
      onSurface: onSurface,
    ),

    scaffoldBackgroundColor: darkBackground,
    canvasColor: surfaceBlack,
    hintColor: onSurface,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceBlack,
      elevation: 2,
      iconTheme: IconThemeData(color: onPrimary),
      titleTextStyle: TextStyle(
        color: onPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: onPrimary,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    // OutlinedButton
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: onPrimary,
        side: const BorderSide(color: onSurface54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    // TextButton
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentBlue,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // FloatingActionButton
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentBlue,
      foregroundColor: onPrimary,
      elevation: 4,
      sizeConstraints: BoxConstraints.tightFor(width: 48, height: 48),
    ),

    // Input-Felder
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceBlack,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: onSurface38),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: accentBlue),
        borderRadius: BorderRadius.circular(8),
      ),
      hintStyle: const TextStyle(color: onSurface38),
      labelStyle: const TextStyle(color: onSurface54),
    ),

    // Karten
    cardTheme: CardTheme(
      color: surfaceBlack,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Text-Styles
    textTheme: const TextTheme(
      // statt headline6 → titleLarge
      titleLarge: TextStyle(
          color: onPrimary, fontSize: 20, fontWeight: FontWeight.bold),
      // statt subtitle1 → titleMedium
      titleMedium: TextStyle(color: onSurface, fontSize: 16),
      // statt bodyText2 → bodyMedium
      bodyMedium: TextStyle(color: onSurface, fontSize: 14),
      // statt button → labelLarge
      labelLarge: TextStyle(
          color: onPrimary, fontSize: 14, fontWeight: FontWeight.w600),
    ),

    // Scrollbar
    scrollbarTheme: ScrollbarThemeData(
      thumbColor:
          MaterialStateProperty.all(accentBlue.withOpacity(0.7)),
      radius: const Radius.circular(8),
      thickness: MaterialStateProperty.all(6),
    ),

    // Sonstiges
    dividerColor: onSurface38,
    dialogBackgroundColor: surfaceBlack,
  );
}
