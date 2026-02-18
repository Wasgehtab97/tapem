import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalTrainingDaysStore {
  const LocalTrainingDaysStore();

  static String _key(String userId) => 'trainingDaysLocal/$userId';

  Future<List<String>> readDayKeys(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) {
      return const <String>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <String>[];
      final set = <String>{
        for (final entry in decoded)
          if (entry != null && entry.toString().trim().isNotEmpty)
            entry.toString().trim(),
      };
      final sorted = set.toList()..sort();
      return sorted;
    } catch (_) {
      await prefs.remove(_key(userId));
      return const <String>[];
    }
  }

  Future<void> writeDayKeys(String userId, Iterable<String> dayKeys) async {
    final prefs = await SharedPreferences.getInstance();
    final unique = <String>{
      for (final key in dayKeys)
        if (key.trim().isNotEmpty) key.trim(),
    }.toList()
      ..sort();
    await prefs.setString(_key(userId), jsonEncode(unique));
  }

  Future<void> addDayKey(String userId, String dayKey) async {
    final normalized = dayKey.trim();
    if (normalized.isEmpty) return;
    final current = await readDayKeys(userId);
    if (current.contains(normalized)) {
      return;
    }
    await writeDayKeys(userId, [...current, normalized]);
  }

  Future<void> removeDayKey(String userId, String dayKey) async {
    final normalized = dayKey.trim();
    if (normalized.isEmpty) return;
    final current = await readDayKeys(userId);
    if (!current.contains(normalized)) return;
    final updated = current.where((entry) => entry != normalized).toList();
    await writeDayKeys(userId, updated);
  }
}

