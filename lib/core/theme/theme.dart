// lib/core/theme/theme.dart

import 'package:flutter/material.dart';

/// Zentrale Farbkonstanten für die App.
class AppColors {
  AppColors._();

  static const primary = Colors.black;
  static const accent = Color(0xFF4169E1); // Royal Blue
  static const scaffoldBackground = Colors.black;
  static const hintText = Color(0xFF82B1FF);

  static const gradientStart = Colors.black;
  static const gradientMiddle = Color(0xFF121212);
  static const gradientEnd = Color(0xFF1E1E1E);
}

/// Liefert das globale Dark-Theme der App, basierend auf [AppColors].
ThemeData appTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.scaffoldBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      titleTextStyle: TextStyle(
        color: AppColors.accent,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: AppColors.accent),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppColors.accent,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: AppColors.accent),
      bodyMedium: TextStyle(color: AppColors.accent),
      bodySmall: TextStyle(
        color: AppColors.accent,
        fontSize: 10,
      ),
      labelLarge: TextStyle(color: AppColors.accent),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.accent,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: AppColors.hintText),
      labelStyle: TextStyle(color: AppColors.accent),
      border: OutlineInputBorder(),
    ),
    iconTheme: const IconThemeData(color: AppColors.accent),
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      background: AppColors.scaffoldBackground,
      error: Colors.redAccent,
    ),
  );
}
