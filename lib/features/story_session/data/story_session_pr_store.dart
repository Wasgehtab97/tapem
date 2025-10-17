import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorySessionPrStore {
  const StorySessionPrStore();

  static String _key(String gymId, String userId) =>
      'storyHistory/pr/$gymId/$userId';

  Future<Map<String, double>> _readMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return <String, double>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(
              key.toString(),
              (value as num?)?.toDouble() ?? 0,
            ));
      }
    } catch (_) {
      await prefs.remove(key);
    }
    return <String, double>{};
  }

  Future<double?> read(
    String gymId,
    String userId,
    String recordKey,
  ) async {
    final map = await _readMap(_key(gymId, userId));
    return map[recordKey];
  }

  Future<void> write(
    String gymId,
    String userId,
    Map<String, double> updates,
  ) async {
    if (updates.isEmpty) return;
    final key = _key(gymId, userId);
    final map = await _readMap(key);
    map.addAll(updates);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(map));
  }
}
