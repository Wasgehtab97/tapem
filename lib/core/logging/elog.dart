import 'dart:convert';
import 'package:flutter/foundation.dart';

void _log(String tag, String event, Map<String, Object?> data) {
  final payload = jsonEncode(data);
  debugPrint('$tag $event $payload');
}

void elogDeviceXp(String event, Map<String, Object?> data) {
  _log('DEVICE_XP', event, data);
}

void elogRank(String event, Map<String, Object?> data) {
  _log('RANK', event, data);
}

void elogUi(String event, Map<String, Object?> data) {
  _log('UI', event, data);
}

void elogError(
  String event,
  Object error,
  StackTrace st, [
  Map<String, Object?> extra = const {},
]) {
  _log('ERROR', event, {
    'error': error.toString(),
    'stack': st.toString(),
    ...extra,
  });
}

