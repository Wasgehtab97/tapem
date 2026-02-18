import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/features/device/domain/models/workout_device_xp_state.dart';

class WorkoutContextCacheStore {
  const WorkoutContextCacheStore();

  static String _noteKey(String gymId, String deviceId, String userId) =>
      'workoutContext/note/$gymId/$deviceId/$userId';

  static String _xpKey(String gymId, String deviceId, String userId) =>
      'workoutContext/xp/$gymId/$deviceId/$userId';

  Future<String> readUserNote({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_noteKey(gymId, deviceId, userId));
    if (raw == null || raw.isEmpty) {
      return '';
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return '';
      }
      return (decoded['note'] as String? ?? '').trim();
    } catch (_) {
      await prefs.remove(_noteKey(gymId, deviceId, userId));
      return '';
    }
  }

  Future<void> writeUserNote({
    required String gymId,
    required String deviceId,
    required String userId,
    required String note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'note': note.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(
      _noteKey(gymId, deviceId, userId),
      jsonEncode(payload),
    );
  }

  Future<WorkoutDeviceXpState> readUserDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_xpKey(gymId, deviceId, userId));
    if (raw == null || raw.isEmpty) {
      return WorkoutDeviceXpState.initial;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return WorkoutDeviceXpState.initial;
      }
      return WorkoutDeviceXpState.fromJson(decoded);
    } catch (_) {
      await prefs.remove(_xpKey(gymId, deviceId, userId));
      return WorkoutDeviceXpState.initial;
    }
  }

  Future<void> writeUserDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
    required WorkoutDeviceXpState stats,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _xpKey(gymId, deviceId, userId),
      jsonEncode(stats.toJson()),
    );
  }
}
