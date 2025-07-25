import 'package:flutter/material.dart';

import '../../features/gym/domain/models/branding.dart';
import 'theme.dart';

/// Lädt dynamisch Themes je nach Gym.
class ThemeLoader extends ChangeNotifier {
  ThemeData _currentTheme = AppTheme.mintDarkTheme;
  ThemeData get theme => _currentTheme;

  /// Setzt das Standard-Dark-Theme.
  void loadDefault() {
    _currentTheme = AppTheme.mintDarkTheme;
    notifyListeners();
  }

  /// Wendet Branding-Daten auf das aktuelle Theme an.
  void applyBranding(Branding? branding) {
    if (branding == null ||
        branding.primaryColor == null ||
        branding.secondaryColor == null) {
      loadDefault();
      return;
    }
    final primary = _parseHex(branding.primaryColor!);
    final accent = _parseHex(branding.secondaryColor!);
    _currentTheme = AppTheme.customTheme(primary: primary, secondary: accent);
    notifyListeners();
  }

  Color _parseHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
