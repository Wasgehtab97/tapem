// lib/core/theme/theme_loader.dart

import 'package:flutter/material.dart';
import '../tenant/tenant_service.dart';

/// Lädt dynamisch ein Theme basierend auf GymConfig.
class ThemeLoader {
  /// Holt aktuelle Config aus TenantService und baut ein ThemeData.
  static Future<ThemeData> loadTheme() async {
    final config = TenantService().config;
    if (config == null) {
      return ThemeData.light();
    }
    // Beispiel: Farbanpassung via Hex-Wert
    final primaryColor = Color(int.parse('0xFF${config.primaryColorHex}'));
    return ThemeData(
      primaryColor: primaryColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
      ),
      // Weitere Anpassungen: TextTheme, ButtonTheme, …
    );
  }
}
