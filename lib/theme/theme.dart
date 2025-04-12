import 'package:flutter/material.dart';

/// Zentrale Farbkonstanten für die königsblau–schwarze App
class AppColors {
  static const Color primary = Colors.black;
  static const Color accent = Color(0xFF4169E1); // Royal Blue
  static const Color scaffoldBackground = Colors.black;
  static const Color appBarText = accent; // Royal Blue als AppBar-Text
  static const Color defaultText = accent; // Royal Blue als Standardtext
  static const Color hintText = Color(0xFF82B1FF); // Helleres Royal Blue für Hint-Texte

  // Optionale zentrale Gradients (für Hintergründe etc.)
  static const Color gradientStart = Colors.black;
  static const Color gradientMiddle = Color(0xFF121212);
  static const Color gradientEnd = Color(0xFF1E1E1E);
}

/// Zentrales Theme für die App
ThemeData appTheme() {
  final base = ThemeData.dark();

  return base.copyWith(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.scaffoldBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      titleTextStyle: const TextStyle(
        color: AppColors.appBarText,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: AppColors.accent),
    ),
    textTheme: const TextTheme(
      // Neue Namenskonventionen:
      titleLarge: TextStyle(
        color: AppColors.appBarText,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: AppColors.defaultText),   // Ersatz für bodyText1
      bodyMedium: TextStyle(color: AppColors.defaultText),    // Ersatz für bodyText2
      bodySmall: TextStyle(color: AppColors.defaultText, fontSize: 10), // Ersatz für caption
      labelLarge: TextStyle(color: AppColors.accent),
      // subtitle1 wurde entfernt – stattdessen können z. B. bodySmall genutzt werden.
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.accent,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: AppColors.hintText),
      labelStyle: TextStyle(color: AppColors.defaultText),
      border: OutlineInputBorder(),
    ),
    iconTheme: const IconThemeData(color: AppColors.accent),
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      background: AppColors.scaffoldBackground,
      error: Colors.redAccent, // Für Fehlerzustände
    ),
  );
}
