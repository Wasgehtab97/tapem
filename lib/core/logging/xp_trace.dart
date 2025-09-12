import 'package:flutter/foundation.dart';

class XpTrace {
  static String buildTraceId({
    required String dayKey,
    required String uid,
    String? deviceId,
    String? sessionId,
  }) {
    String suf(String? s) => (s == null || s.isEmpty)
        ? ''
        : (s.length <= 4 ? s : s.substring(s.length - 4));
    final u = suf(uid);
    final d = suf(deviceId);
    final sfx = suf(sessionId);
    return '$dayKey:$u:$d:$sfx';
  }

  static void log(String stage, Map<String, Object?> data) {
    if (!kDebugMode) return;
    final payload = data.entries.map((e) => '${e.key}=${e.value}').join(' ');
    debugPrint('XP/$stage $payload');
  }
}
