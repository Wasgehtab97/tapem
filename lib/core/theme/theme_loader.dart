// lib/core/theme/theme_loader.dart

import 'package:flutter/material.dart';
import '../tenant/tenant_service.dart';

/// Lädt dynamisch ein Theme basierend auf der im TenantService gespeicherten GymConfig.
class ThemeLoader {
  /// Holt aktuelle Config aus TenantService und erstellt ein ThemeData.
  static Future<ThemeData> loadTheme() async {
    final config = TenantService().config;

    // Fallback auf Standard-Light-Theme, wenn noch keine Config geladen
    if (config == null) {
      return ThemeData.light();
    }

    // Primäre Farbe direkt aus dem gespeicherten int-Wert verwenden
    final Color primaryColor = Color(config.primaryColorValue);

    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
