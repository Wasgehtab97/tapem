// lib/core/utils/logger.dart

class AppLogger {
  static void log(String message) {
    final time = DateTime.now().toIso8601String();
    // Hier könntest du erweitern: file logging, log levels, …
    print('[$time] $message');
  }

  static void error(String message, [Object? error]) {
    final time = DateTime.now().toIso8601String();
    print('[$time] ERROR: $message ${error ?? ''}');
  }
}
