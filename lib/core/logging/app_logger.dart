import 'dart:developer';

enum AppLogCategory { general, audio, timer }

enum AppLogLevel { info, warning, error }

const bool kAudioVerboseLogs = bool.fromEnvironment(
  'AUDIO_VERBOSE_LOGS',
  defaultValue: true,
);

String _stringifyValue(Object? value) {
  if (value == null) return 'null';
  if (value is DateTime) {
    return value.toUtc().toIso8601String();
  }
  if (value is Duration) {
    return value.inMicroseconds.toString();
  }
  return value.toString();
}

String _formatDetails(Map<String, Object?> details) {
  if (details.isEmpty) {
    return '{}';
  }
  final entries = details.entries
      .map((e) => '${e.key}=${_stringifyValue(e.value)}')
      .join(', ');
  return '{${entries}}';
}

void logAppEvent({
  required AppLogCategory category,
  required String name,
  AppLogLevel level = AppLogLevel.info,
  String? timerId,
  Map<String, Object?> details = const {},
  Object? error,
  StackTrace? stackTrace,
}) {
  final ts = DateTime.now().toUtc().toIso8601String();
  final categoryTag = category.name.toUpperCase();
  final levelTag = level.name.toUpperCase();
  final tid = timerId ?? '-';
  final msg =
      '[APP][$categoryTag][$tid] name=$name level=$levelTag ts=$ts ${_formatDetails(details)}';
  log(
    msg,
    name: 'APP',
    error: error,
    stackTrace: stackTrace,
  );
}
