import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/time/logic_day.dart';

class DailyStatsCacheEntry {
  const DailyStatsCacheEntry({
    required this.xp,
    required this.cachedAt,
    required this.totalXp,
    required this.dayKey,
    this.computedTotalXp,
    this.rulesetId,
    this.rulesetVersion,
    this.components = const <Map<String, dynamic>>[],
    this.penalties = const <Map<String, dynamic>>[],
  });

  final int xp;
  final DateTime cachedAt;
  final int totalXp;
  final String dayKey;
  final int? computedTotalXp;
  final String? rulesetId;
  final int? rulesetVersion;
  final List<Map<String, dynamic>> components;
  final List<Map<String, dynamic>> penalties;

  bool isSameCalendarDay(DateTime other) {
    return dayKey == logicDayKey(other);
  }

  Map<String, dynamic> toJson() => {
    'xp': xp,
    'totalXp': totalXp,
    'dayKey': dayKey,
    'cachedAt': cachedAt.toIso8601String(),
    if (computedTotalXp != null) 'computedTotalXp': computedTotalXp,
    if (rulesetId != null) 'rulesetId': rulesetId,
    if (rulesetVersion != null) 'rulesetVersion': rulesetVersion,
    if (components.isNotEmpty) 'components': components,
    if (penalties.isNotEmpty) 'penalties': penalties,
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
    final computedValue = (json['computedTotalXp'] as num?)?.toInt();
    final rulesetIdValue = (json['rulesetId'] as String?)?.trim();
    final rulesetVersionValue = (json['rulesetVersion'] as num?)?.toInt();
    final storedDayKey = json['dayKey'] as String? ?? logicDayKey(timestamp);
    final rawXp = xpValue.toInt();
    final totalXp = totalValue ?? rawXp;
    final computedTotalXp = computedValue ?? totalXp;
    final components = _decodeMapList(json['components']);
    final penalties = _decodeMapList(json['penalties']);
    return DailyStatsCacheEntry(
      xp: rawXp,
      cachedAt: timestamp,
      totalXp: totalXp,
      dayKey: storedDayKey,
      computedTotalXp: computedTotalXp,
      rulesetId: rulesetIdValue == null || rulesetIdValue.isEmpty
          ? null
          : rulesetIdValue,
      rulesetVersion: rulesetVersionValue,
      components: components,
      penalties: penalties,
    );
  }
}

List<Map<String, dynamic>> _decodeMapList(dynamic raw) {
  if (raw is! List) return const <Map<String, dynamic>>[];
  return raw
      .whereType<Map>()
      .map((entry) => entry.map((key, value) => MapEntry('$key', value)))
      .toList();
}

abstract class DailyStatsCache {
  Future<DailyStatsCacheEntry?> read(String gymId, String userId);

  Future<DailyStatsCacheEntry> write(
    String gymId,
    String userId,
    int xp,
    DateTime cachedAt, {
    int? totalXp,
    int? computedTotalXp,
    String? rulesetId,
    int? rulesetVersion,
    List<Map<String, dynamic>>? components,
    List<Map<String, dynamic>>? penalties,
  });

  Future<DailyStatsCacheEntry> writeTotal(
    String gymId,
    String userId,
    int totalXp,
    DateTime cachedAt, {
    int? dayXp,
    int? computedTotalXp,
    String? rulesetId,
    int? rulesetVersion,
    List<Map<String, dynamic>>? components,
    List<Map<String, dynamic>>? penalties,
  });

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
    int? computedTotalXp,
    String? rulesetId,
    int? rulesetVersion,
    List<Map<String, dynamic>>? components,
    List<Map<String, dynamic>>? penalties,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = DailyStatsCacheEntry(
      xp: xp,
      cachedAt: cachedAt,
      totalXp: totalXp ?? xp,
      dayKey: logicDayKey(cachedAt),
      computedTotalXp: computedTotalXp ?? totalXp ?? xp,
      rulesetId: rulesetId,
      rulesetVersion: rulesetVersion,
      components: components ?? const <Map<String, dynamic>>[],
      penalties: penalties ?? const <Map<String, dynamic>>[],
    );
    await prefs.setString(_key(gymId, userId), jsonEncode(entry.toJson()));
    return entry;
  }

  @override
  Future<DailyStatsCacheEntry> writeTotal(
    String gymId,
    String userId,
    int totalXp,
    DateTime cachedAt, {
    int? dayXp,
    int? computedTotalXp,
    String? rulesetId,
    int? rulesetVersion,
    List<Map<String, dynamic>>? components,
    List<Map<String, dynamic>>? penalties,
  }) async {
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
    }
    var resolvedDailyXp = dayXp ?? (totalXp - baseline);
    if (resolvedDailyXp < 0) {
      resolvedDailyXp = 0;
    }

    final resolvedComponents =
        components ??
        (existing != null && existing.dayKey == dayKey
            ? existing.components
            : const <Map<String, dynamic>>[]);
    final resolvedPenalties =
        penalties ??
        (existing != null && existing.dayKey == dayKey
            ? existing.penalties
            : const <Map<String, dynamic>>[]);
    final resolvedRulesetId =
        rulesetId ??
        (existing != null && existing.dayKey == dayKey
            ? existing.rulesetId
            : null);
    final resolvedRulesetVersion =
        rulesetVersion ??
        (existing != null && existing.dayKey == dayKey
            ? existing.rulesetVersion
            : null);

    final entry = DailyStatsCacheEntry(
      xp: resolvedDailyXp,
      cachedAt: cachedAt,
      totalXp: totalXp,
      dayKey: dayKey,
      computedTotalXp: computedTotalXp ?? totalXp,
      rulesetId: resolvedRulesetId,
      rulesetVersion: resolvedRulesetVersion,
      components: resolvedComponents,
      penalties: resolvedPenalties,
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
    final adjustedDailyXp = dailyXp < 0 ? 0 : dailyXp;
    final adjustedTotal = totalXp < 0 ? 0 : totalXp;
    final resolvedComponents = existing != null && existing.dayKey == dayKey
        ? existing.components
        : const <Map<String, dynamic>>[];
    final resolvedPenalties = existing != null && existing.dayKey == dayKey
        ? existing.penalties
        : const <Map<String, dynamic>>[];
    final resolvedRulesetId = existing != null && existing.dayKey == dayKey
        ? existing.rulesetId
        : null;
    final resolvedRulesetVersion = existing != null && existing.dayKey == dayKey
        ? existing.rulesetVersion
        : null;

    final entry = DailyStatsCacheEntry(
      xp: adjustedDailyXp,
      cachedAt: now,
      totalXp: adjustedTotal,
      dayKey: dayKey,
      computedTotalXp: adjustedTotal,
      rulesetId: resolvedRulesetId,
      rulesetVersion: resolvedRulesetVersion,
      components: resolvedComponents,
      penalties: resolvedPenalties,
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
