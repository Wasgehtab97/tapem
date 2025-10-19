import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorySessionPrCacheEntry {
  const StorySessionPrCacheEntry({
    required this.value,
    this.dayKey,
  });

  final double value;
  final String? dayKey;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'value': value,
      if (dayKey != null && dayKey!.isNotEmpty) 'dayKey': dayKey,
    };
  }

  static StorySessionPrCacheEntry? fromJson(dynamic source) {
    if (source is num) {
      return StorySessionPrCacheEntry(value: source.toDouble());
    }
    if (source is Map) {
      final rawValue = source['value'];
      final value = (rawValue as num?)?.toDouble();
      if (value == null) return null;
      final rawDayKey = source['dayKey'];
      final dayKey = rawDayKey == null || rawDayKey.toString().isEmpty
          ? null
          : rawDayKey.toString();
      return StorySessionPrCacheEntry(
        value: value,
        dayKey: dayKey,
      );
    }
    return null;
  }
}

class StorySessionPrStore {
  const StorySessionPrStore();

  static String _key(String gymId, String userId) =>
      'storyHistory/pr/$gymId/$userId';

  Future<Map<String, StorySessionPrCacheEntry>> _readEntries(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return <String, StorySessionPrCacheEntry>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final entries = <String, StorySessionPrCacheEntry>{};
        decoded.forEach((k, value) {
          final entry = StorySessionPrCacheEntry.fromJson(value);
          if (entry != null) {
            entries[k.toString()] = entry;
          }
        });
        return entries;
      }
    } catch (_) {
      await prefs.remove(key);
    }
    return <String, StorySessionPrCacheEntry>{};
  }

  Future<StorySessionPrCacheEntry?> readEntry(
    String gymId,
    String userId,
    String recordKey,
  ) async {
    final map = await _readEntries(_key(gymId, userId));
    return map[recordKey];
  }

  Future<double?> read(
    String gymId,
    String userId,
    String recordKey,
  ) async {
    final entry = await readEntry(gymId, userId, recordKey);
    return entry?.value;
  }

  Future<void> write(
    String gymId,
    String userId,
    Map<String, StorySessionPrCacheEntry> updates,
  ) async {
    if (updates.isEmpty) return;
    final key = _key(gymId, userId);
    final map = await _readEntries(key);
    map.addAll(updates);
    final prefs = await SharedPreferences.getInstance();
    final serialized = <String, dynamic>{
      for (final entry in map.entries) entry.key: entry.value.toJson(),
    };
    await prefs.setString(key, jsonEncode(serialized));
  }
}
