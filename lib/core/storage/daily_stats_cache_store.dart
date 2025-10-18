import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';

class DailyStatsCacheEntry {
  const DailyStatsCacheEntry({
    required this.xp,
    required this.cachedAt,
    required this.totalXp,
    required this.dayKey,
  });

  final int xp;
  final DateTime cachedAt;
  final int totalXp;
  final String dayKey;

  bool isSameCalendarDay(DateTime other) {
    return dayKey == logicDayKey(other);
  }

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'totalXp': totalXp,
        'dayKey': dayKey,
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
    final totalValue = (json['totalXp'] as num?)?.toInt();
    final storedDayKey = json['dayKey'] as String? ?? logicDayKey(timestamp);
    final rawXp = xpValue.toInt();
    final totalXp = totalValue ?? rawXp;
    final xpPerSession = LevelService.xpPerSession;
    final sanitizedXp = totalValue == null && rawXp > xpPerSession
        ? xpPerSession
        : rawXp;
    return DailyStatsCacheEntry(
      xp: sanitizedXp,
      cachedAt: timestamp,
      totalXp: totalXp,
      dayKey: storedDayKey,
    );
  }
}

abstract class DailyStatsCache {
  Future<DailyStatsCacheEntry?> read(String gymId, String userId);

  Future<DailyStatsCacheEntry> write(
    String gymId,
    String userId,
    int xp,
    DateTime cachedAt, {
    int? totalXp,
  });

  Future<DailyStatsCacheEntry> writeTotal(
    String gymId,
    String userId,
    int totalXp,
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
    DateTime cachedAt, {
    int? totalXp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = DailyStatsCacheEntry(
      xp: xp,
      cachedAt: cachedAt,
      totalXp: totalXp ?? xp,
      dayKey: logicDayKey(cachedAt),
    );
    await prefs.setString(_key(gymId, userId), jsonEncode(entry.toJson()));
    return entry;
  }

  @override
  Future<DailyStatsCacheEntry> writeTotal(
    String gymId,
    String userId,
    int totalXp,
    DateTime cachedAt,
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

    final dayKey = logicDayKey(cachedAt);
    final prevTotal = existing?.totalXp ?? existing?.xp ?? 0;
    var baseline = prevTotal;
    if (existing != null && existing.dayKey == dayKey) {
      baseline = prevTotal - existing.xp;
      if (existing.totalXp == existing.xp && existing.xp > LevelService.xpPerSession) {
        baseline = prevTotal - LevelService.xpPerSession;
      }
    }
    var dailyXp = totalXp - baseline;
    if (dailyXp < 0) {
      dailyXp = 0;
    }
    if (dailyXp > LevelService.xpPerSession) {
      dailyXp = LevelService.xpPerSession;
    }

    final entry = DailyStatsCacheEntry(
      xp: dailyXp,
      cachedAt: cachedAt,
      totalXp: totalXp,
      dayKey: dayKey,
    );
    await prefs.setString(key, jsonEncode(entry.toJson()));
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

    final dayKey = logicDayKey(now);
    final prevTotal = existing?.totalXp ?? existing?.xp ?? 0;
    final totalXp = prevTotal + delta;
    final dailyXp = (existing == null || existing.dayKey != dayKey)
        ? delta
        : existing.xp + delta;

    final entry = DailyStatsCacheEntry(
      xp: dailyXp,
      cachedAt: now,
      totalXp: totalXp,
      dayKey: dayKey,
    );
    await prefs.setString(key, jsonEncode(entry.toJson()));
    return entry;
  }

  @override
  Future<void> clear(String gymId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(gymId, userId));
  }
}
