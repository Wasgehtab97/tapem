import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/story_session_summary.dart';

class StorySessionSummaryStore {
  const StorySessionSummaryStore();

  static String _key(String gymId, String userId, String dayKey) =>
      'storySessionSummary/$gymId/$userId/$dayKey';

  Future<StorySessionSummary?> read(
    String gymId,
    String userId,
    String dayKey,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(gymId, userId, dayKey));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return StorySessionSummary.fromJson(map);
    } catch (_) {
      await prefs.remove(_key(gymId, userId, dayKey));
      return null;
    }
  }

  Future<void> write(StorySessionSummary summary) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(summary.gymId, summary.userId, summary.dayKey);
    await prefs.setString(key, jsonEncode(summary.toJson()));
  }
}
