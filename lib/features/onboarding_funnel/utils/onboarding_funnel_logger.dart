import 'dart:developer' as developer;

void logOnboardingFunnel(
  String message, {
  String scope = 'OnboardingFunnel',
  Map<String, Object?>? data,
  Object? error,
  StackTrace? stackTrace,
}) {
  final buffer = StringBuffer(message);
  if (data != null && data.isNotEmpty) {
    final formatted = data.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(', ');
    buffer
      ..write(' | ')
      ..write(formatted);
  }

  developer.log(
    buffer.toString(),
    name: scope,
    error: error,
    stackTrace: stackTrace,
  );
}
