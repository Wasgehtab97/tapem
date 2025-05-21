// lib/core/theme/theme_loader.dart

import 'package:flutter/material.dart';
import 'theme.dart';

/// Mit diesem Provider kannst du später dynamisch Themes wechseln,
/// z.B. je nach Gym oder Nutzer-Einstellungen.
class ThemeLoader extends ChangeNotifier {
  ThemeData _currentTheme = AppTheme.darkTheme;
  ThemeData get theme => _currentTheme;

  /// Lädt das Standard-Dark-Theme
  void loadDefault() {
    _currentTheme = AppTheme.darkTheme;
    notifyListeners();
  }

  /// Beispiel: unterschiedliche Themes pro Gym laden.
  void loadGymTheme(String gymId) {
    if (gymId == 'blueGym') {
      // Wir kopieren über colorScheme.copyWith
      final scheme = AppTheme.darkTheme.colorScheme.copyWith(
        primary: Colors.blueAccent,
        secondary: Colors.lightBlueAccent,
      );
      _currentTheme = AppTheme.darkTheme.copyWith(colorScheme: scheme);
    } else {
      _currentTheme = AppTheme.darkTheme;
    }
    notifyListeners();
  }
}
