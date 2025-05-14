// lib/core/utils/logger.dart

/// Einfache Logging-Klasse für Debug- und Fehlerausgaben.
class AppLogger {
  /// Gibt eine Info-Nachricht mit Zeitstempel auf der Konsole aus.
  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] INFO: $message');
  }

  /// Gibt eine Fehlermeldung mit Zeitstempel auf der Konsole aus.
  static void error(String message, [Object? error]) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] ERROR: $message ${error ?? ''}');
  }
}
