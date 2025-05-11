// lib/core/theme/theme_loader.dart

import 'package:flutter/material.dart';
import '../tenant/tenant_service.dart';
import '../utils/logger.dart';

/// Lädt dynamisch ein Theme basierend auf der im TenantService
/// gespeicherten Gym-Config.
class ThemeLoader {
  /// Holt die aktuell geladene Gym-Config und erstellt ein ThemeData.
  static Future<ThemeData> loadTheme() async {
    final cfg = TenantService().config;

    // 1) Fallback auf Standard-Theme, wenn noch keine GymConfig geladen
    if (cfg == null) {
      AppLogger.log('No GymConfig found, using light fallback');
      return ThemeData.light();
    }

    AppLogger.log('Applying GymConfig theme for "${cfg.displayName}"');

    // 2) Basis-Theme anpassen
    final base = ThemeData.dark();
    return base.copyWith(
      primaryColor: cfg.primaryColor,
      scaffoldBackgroundColor: base.scaffoldBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: cfg.primaryColor,
        titleTextStyle: TextStyle(
          color: cfg.accentColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: cfg.accentColor),
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: cfg.primaryColor,
        secondary: cfg.accentColor,
        background: base.colorScheme.background,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cfg.primaryColor,
          foregroundColor: cfg.accentColor,
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
