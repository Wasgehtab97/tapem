import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DailyStatsCacheEntry {
  const DailyStatsCacheEntry({
    required this.xp,
    required this.cachedAt,
  });

  final int xp;
  final DateTime cachedAt;

  bool isSameCalendarDay(DateTime other) {
    return cachedAt.year == other.year &&
        cachedAt.month == other.month &&
        cachedAt.day == other.day;
  }

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'cachedAt': cachedAt.toIso8601String(),
      };

  static DailyStatsCacheEntry? fromJson(Map<String, dynamic> json) {
    final xpValue = json['xp'];
    final cachedAtValue = json['cachedAt'];
    if (xpValue is! num || cachedAtValue is! String) {
      return null;
    }
    final timestamp = DateTime.tryParse(cachedAtValue);
    if (timestamp == null) {
      return null;
    }
    return DailyStatsCacheEntry(
      xp: xpValue.toInt(),
      cachedAt: timestamp,
    );
  }
}

abstract class DailyStatsCache {
  Future<DailyStatsCacheEntry?> read(String gymId, String userId);

  Future<DailyStatsCacheEntry> write(
    String gymId,
    String userId,
    int xp,
    DateTime cachedAt,
  );

  Future<DailyStatsCacheEntry> increment(
    String gymId,
    String userId,
    int delta,
    DateTime now,
  );

  Future<void> clear(String gymId, String userId);
}

class DailyStatsCacheStore implements DailyStatsCache {
  const DailyStatsCacheStore();

  static String _key(String gymId, String userId) =>
      'dailyStatsCache/$gymId/$userId';

  @override
  Future<DailyStatsCacheEntry?> read(String gymId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(gymId, userId));
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return DailyStatsCacheEntry.fromJson(decoded);
    } catch (_) {
      await prefs.remove(_key(gymId, userId));
      return null;
    }
  }

  @override
  Future<DailyStatsCacheEntry> write(
    String gymId,
    String userId,
    int xp,
    DateTime cachedAt,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = DailyStatsCacheEntry(xp: xp, cachedAt: cachedAt);
    await prefs.setString(_key(gymId, userId), jsonEncode(entry.toJson()));
    return entry;
  }

  @override
  Future<DailyStatsCacheEntry> increment(
    String gymId,
    String userId,
    int delta,
    DateTime now,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(gymId, userId);
    final raw = prefs.getString(key);
    DailyStatsCacheEntry? existing;
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          existing = DailyStatsCacheEntry.fromJson(decoded);
        }
      } catch (_) {
        existing = null;
      }
    }

    if (existing == null || !existing.isSameCalendarDay(now)) {
      final fresh = DailyStatsCacheEntry(
        xp: delta,
        cachedAt: now,
      );
      await prefs.setString(key, jsonEncode(fresh.toJson()));
      return fresh;
    }

    final updated = DailyStatsCacheEntry(
      xp: existing.xp + delta,
      cachedAt: now,
    );
    await prefs.setString(key, jsonEncode(updated.toJson()));
    return updated;
  }

  @override
  Future<void> clear(String gymId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(gymId, userId));
  }
}
