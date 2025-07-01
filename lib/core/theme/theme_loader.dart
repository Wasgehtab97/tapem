import 'package:flutter/material.dart';
import 'theme.dart';

/// Lädt dynamisch Themes je nach Gym.
class ThemeLoader extends ChangeNotifier {
  ThemeData _currentTheme = AppTheme.darkTheme;
  ThemeData get theme => _currentTheme;

  /// Setzt Standard-Dark-Theme (Blau).
  void loadDefault() {
    _currentTheme = AppTheme.darkTheme;
    notifyListeners();
  }

  /// Lädt je nach gymId entweder Blau- oder Grün-Theme.
  void loadGymTheme(String gymId) {
    switch (gymId) {
      case 'gym_02':
        _currentTheme = AppTheme.greenDarkTheme;
        break;
      case 'gym_01':
      default:
        _currentTheme = AppTheme.darkTheme;
    }
    notifyListeners();
  }
}
