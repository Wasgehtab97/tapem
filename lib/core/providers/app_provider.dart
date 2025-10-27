// lib/core/providers/app_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Steuert app-weite Einstellungen (z.B. Sprache).
class AppProvider extends ChangeNotifier {
  AppProvider({SharedPreferences? preferences}) : _preferences = preferences {
    final prefs = _preferences;
    if (prefs != null) {
      _applyStoredLocale(prefs, notify: false);
    } else {
      _restoreLocale();
    }
  }

  static const _prefsKey = 'app_locale';

  SharedPreferences? _preferences;
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
    _persistLocale(newLocale);
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

  Future<void> _restoreLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _preferences = prefs;
      _applyStoredLocale(prefs, notify: true);
    } catch (e) {
      debugPrint('[AppProvider] Failed to restore locale: $e');
    }
  }

  void _applyStoredLocale(SharedPreferences prefs, {required bool notify}) {
    final stored = prefs.getString(_prefsKey);
    final restored = stored != null && stored.isNotEmpty
        ? _localeFromStorage(stored)
        : null;
    final shouldNotify = restored != _locale;
    _locale = restored;
    if (notify && shouldNotify) {
      notifyListeners();
    }
  }

  Future<void> _persistLocale(Locale? locale) async {
    try {
      final prefs = _preferences ??= await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, _localeToStorage(locale));
      }
    } catch (e) {
      debugPrint('[AppProvider] Failed to persist locale: $e');
    }
  }

  String _localeToStorage(Locale locale) {
    final country = locale.countryCode;
    if (country == null || country.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}_$country';
  }

  Locale _localeFromStorage(String value) {
    final segments = value.split('_');
    if (segments.isEmpty) {
      return Locale(value);
    }
    final language = segments[0];
    if (language.isEmpty) {
      return Locale(value);
    }
    if (segments.length == 1 || segments[1].isEmpty) {
      return Locale(language);
    }
    return Locale(language, segments[1]);
  }
}
