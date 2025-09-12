import 'package:flutter/foundation.dart';
import 'package:tapem/core/time/logic_day.dart';

const bool _enableXpTrace = false;

String _suffix4(String value) {
  if (value.length <= 4) return value;
  return value.substring(value.length - 4);
}

String buildXpTraceId({
  required String uid,
  required String deviceId,
  required String sessionId,
  DateTime? date,
}) {
  final dayKey = logicDayKey((date ?? DateTime.now()).toUtc());
  return '$dayKey:${_suffix4(uid)}:${_suffix4(deviceId)}:${_suffix4(sessionId)}';
}

void xpLog(String stage, Map<String, Object?> data) {
  if (!_enableXpTrace) return;
  final parts = data.entries.map((e) => '${e.key}=${e.value}').join(' ');
  debugPrint('XP/$stage $parts');
}
