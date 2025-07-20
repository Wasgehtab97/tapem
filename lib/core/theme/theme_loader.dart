import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Lädt Theme-Konfiguration aus Firestore anhand der Gym-ID.
  Future<void> loadGymTheme(String gymId) async {
    if (gymId.isEmpty) {
      loadDefault();
      return;
    }
    final doc =
        await FirebaseFirestore.instance.collection('gyms').doc(gymId).get();
    if (doc.exists) {
      final data = doc.data()!;
      final primaryHex = data['primaryColor'] as String?;
      final accentHex = data['accentColor'] as String?;
      if (primaryHex != null && accentHex != null) {
        final primary = _parseHex(primaryHex);
        final accent = _parseHex(accentHex);
        _currentTheme = AppTheme.customTheme(primary: primary, secondary: accent);
        notifyListeners();
        return;
      }
    }
    _currentTheme = AppTheme.darkTheme;
    notifyListeners();
  }

  Color _parseHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
