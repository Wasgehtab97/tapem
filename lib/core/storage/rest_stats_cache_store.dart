import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/features/rest_stats/domain/models/rest_stat_summary.dart';

class RestStatsCacheEntry {
  const RestStatsCacheEntry({
    required this.stats,
    required this.cachedAt,
  });

  final List<RestStatSummary> stats;
  final DateTime cachedAt;

  bool isExpired(DateTime now, Duration ttl) => now.difference(cachedAt) > ttl;

  Map<String, dynamic> toJson() => {
        'cachedAt': cachedAt.toIso8601String(),
        'stats': stats.map((s) => s.toJson()).toList(),
      };

  factory RestStatsCacheEntry.fromJson(Map<String, dynamic> json) {
    final cachedAtRaw = json['cachedAt'];
    if (cachedAtRaw is! String) {
      throw const FormatException('Invalid cachedAt');
    }
    final cachedAt = DateTime.tryParse(cachedAtRaw);
    if (cachedAt == null) {
      throw const FormatException('Invalid cachedAt date');
    }
    final rawStats = json['stats'];
    if (rawStats is! List) {
      throw const FormatException('Invalid stats');
    }
    final stats = rawStats
        .whereType<Map<String, dynamic>>()
        .map(RestStatSummary.fromJson)
        .toList();
    return RestStatsCacheEntry(stats: stats, cachedAt: cachedAt);
  }
}

class RestStatsCacheStore {
  const RestStatsCacheStore();

  static String _key(String gymId, String userId) => 'restStats/$gymId/$userId';

  Future<RestStatsCacheEntry?> read(String gymId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(gymId, userId));
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await prefs.remove(_key(gymId, userId));
        return null;
      }
      return RestStatsCacheEntry.fromJson(decoded);
    } catch (_) {
      await prefs.remove(_key(gymId, userId));
      return null;
    }
  }

  Future<void> write(
    String gymId,
    String userId,
    RestStatsCacheEntry entry,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(gymId, userId), jsonEncode(entry.toJson()));
  }

  Future<void> clear(String gymId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(gymId, userId));
  }
}
