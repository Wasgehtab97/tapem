import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorySessionHistoryStore {
  const StorySessionHistoryStore();

  static String _deviceKey(String gymId, String userId) =>
      'storyHistory/devices/$gymId/$userId';

  static String _exerciseKey(String gymId, String userId) =>
      'storyHistory/exercises/$gymId/$userId';

  Future<Set<String>> _readSet(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toSet();
      }
    } catch (_) {
      await prefs.remove(key);
    }
    return <String>{};
  }

  Future<void> _writeSet(String key, Set<String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(values.toList()));
  }

  Future<bool> hasSeenDevice(String gymId, String userId, String deviceId) async {
    final set = await _readSet(_deviceKey(gymId, userId));
    return set.contains(deviceId);
  }

  Future<void> markDeviceSeen(
    String gymId,
    String userId,
    Iterable<String> deviceIds,
  ) async {
    if (deviceIds.isEmpty) return;
    final key = _deviceKey(gymId, userId);
    final set = await _readSet(key);
    set.addAll(deviceIds);
    await _writeSet(key, set);
  }

  Future<bool> hasSeenExercise(
    String gymId,
    String userId,
    String deviceId,
    String exerciseId,
  ) async {
    final set = await _readSet(_exerciseKey(gymId, userId));
    return set.contains('$deviceId::$exerciseId');
  }

  Future<void> markExerciseSeen(
    String gymId,
    String userId,
    Iterable<MapEntry<String, String>> deviceExercisePairs,
  ) async {
    if (deviceExercisePairs.isEmpty) return;
    final key = _exerciseKey(gymId, userId);
    final set = await _readSet(key);
    for (final entry in deviceExercisePairs) {
      set.add('${entry.key}::${entry.value}');
    }
    await _writeSet(key, set);
  }
}
