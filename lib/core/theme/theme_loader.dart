// lib/core/theme/theme_loader.dart

import 'package:flutter/material.dart';
import 'package:tapem/domain/models/gym_config.dart'; // Stelle sicher, dass diese Datei existiert

/// Lädt ein dynamisches Theme.
/// Aktuell liefert es das helle Material-Theme mit Material 3.
/// Über [loadThemeFromConfig] kannst du später ein konfiguriertes Theme erzeugen.
class ThemeLoader {
  /// Gibt aktuell ein einfaches Light-Theme zurück.
  static Future<ThemeData> loadTheme() async {
    return ThemeData.light().copyWith(useMaterial3: true);
  }

  /// Erzeugt ein Theme auf Basis einer GymConfig (farblich anpassbar).
  static ThemeData loadThemeFromConfig(GymConfig config) {
    final scheme = ColorScheme.fromSeed(
      seedColor: config.primaryColor,
      primary: config.primaryColor,
      secondary: config.accentColor,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.secondary,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 18,
          fontFamily: 'Roboto',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }
}
