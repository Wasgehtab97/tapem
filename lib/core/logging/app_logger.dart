import 'package:flutter/foundation.dart';

enum AppLogLevel { debug, info, warn, error }

class AppLogger {
  const AppLogger._();

  static void d(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(AppLogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void i(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(AppLogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void w(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(AppLogLevel.warn, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(AppLogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    AppLogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final isRelease = kReleaseMode;
    if (isRelease && (level == AppLogLevel.debug || level == AppLogLevel.info)) {
      return;
    }
    final levelLabel = switch (level) {
      AppLogLevel.debug => 'D',
      AppLogLevel.info => 'I',
      AppLogLevel.warn => 'W',
      AppLogLevel.error => 'E',
    };
    final prefix = tag == null || tag.isEmpty ? '' : '[$tag] ';
    var line = '$levelLabel $prefix$message';
    if (error != null) {
      line = '$line error=$error';
    }
    debugPrint(line);
    if (stackTrace != null && !isRelease) {
      debugPrint(stackTrace.toString());
    }
  }
}
