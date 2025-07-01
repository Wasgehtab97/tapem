// lib/core/providers/app_provider.dart

import 'package:flutter/material.dart';

/// Steuert app-weite Einstellungen (z.B. Sprache).
class AppProvider extends ChangeNotifier {
  Locale? _locale;

  /// Aktuelle App-Sprache. Null = System-Voreinstellung.
  Locale? get locale => _locale;

  /// Setzt die App-Sprache und benachrichtigt die Listener.
  ///
  /// Wenn [newLocale] null ist, wird wieder die System-Sprache verwendet.
  void setLocale(Locale? newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      notifyListeners();
    }
  }

  /// Setzt die Sprache zurück auf die System-Voreinstellung.
  void resetLocale() => setLocale(null);

  /// Aufräumarbeiten beim Logout (optional).
  ///
  /// Hier könntest du z.B. alle Einstellungen zurücksetzen:
  /// ```dart
  /// _locale = null;
  /// notifyListeners();
  /// ```
  void logout() {
    // Beispiel: Zurücksetzen aller Einstellungen
    // _locale = null;
    // notifyListeners();
  }
}
