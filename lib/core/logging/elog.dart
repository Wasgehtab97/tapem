import 'dart:convert';
import 'package:flutter/foundation.dart';

void elogDeviceXp(String event, Map<String, dynamic> payload) {
  final data = jsonEncode(payload);
  debugPrint('DEVICE_XP_$event $data');
}
