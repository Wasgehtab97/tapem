import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/favorite_exercise_usage.dart';

class ProfileCacheEntry {
  const ProfileCacheEntry({
    required this.trainingDates,
    required this.trainingDayDates,
    required this.totalTrainingDays,
    required this.averageTrainingDaysPerWeek,
    required this.favoriteExerciseName,
    required this.favoriteExerciseUsages,
    this.favoriteExercisesGymId,
    required this.cachedAt,
  });

  final List<String> trainingDates;
  final List<DateTime> trainingDayDates;
  final int totalTrainingDays;
  final double averageTrainingDaysPerWeek;
  final String? favoriteExerciseName;
  final List<FavoriteExerciseUsage> favoriteExerciseUsages;
  final String? favoriteExercisesGymId;
  final DateTime cachedAt;

  bool isExpired(DateTime now, Duration ttl) => now.difference(cachedAt) > ttl;

  Map<String, dynamic> toJson() => {
        'trainingDates': trainingDates,
        'trainingDayDates':
            trainingDayDates.map((date) => date.toIso8601String()).toList(),
        'totalTrainingDays': totalTrainingDays,
        'averageTrainingDaysPerWeek': averageTrainingDaysPerWeek,
        'favoriteExerciseName': favoriteExerciseName,
        'favoriteExerciseUsages':
            favoriteExerciseUsages.map((usage) => usage.toJson()).toList(),
        'favoriteExercisesGymId': favoriteExercisesGymId,
        'cachedAt': cachedAt.toIso8601String(),
      };

  static ProfileCacheEntry? fromJson(Map<String, dynamic> json) {
    try {
      final trainingDates = (json['trainingDates'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const <String>[];
      final trainingDayDates = (json['trainingDayDates'] as List<dynamic>?)
              ?.whereType<String>()
              .map(DateTime.parse)
              .toList() ??
          const <DateTime>[];
      final totalTrainingDays = (json['totalTrainingDays'] as num?)?.toInt() ?? 0;
      final averageTrainingDaysPerWeek =
          (json['averageTrainingDaysPerWeek'] as num?)?.toDouble() ?? 0.0;
      final favoriteExerciseName = json['favoriteExerciseName'] as String?;
      final favoriteExerciseUsages = (json['favoriteExerciseUsages'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(FavoriteExerciseUsage.fromJson)
              .toList() ??
          const <FavoriteExerciseUsage>[];
      final favoriteExercisesGymId = json['favoriteExercisesGymId'] as String?;
      final cachedAtRaw = json['cachedAt'];
      if (cachedAtRaw is! String) {
        return null;
      }
      final cachedAt = DateTime.tryParse(cachedAtRaw);
      if (cachedAt == null) {
        return null;
      }
      return ProfileCacheEntry(
        trainingDates: trainingDates,
        trainingDayDates: trainingDayDates,
        totalTrainingDays: totalTrainingDays,
        averageTrainingDaysPerWeek: averageTrainingDaysPerWeek,
        favoriteExerciseName: favoriteExerciseName,
        favoriteExerciseUsages: favoriteExerciseUsages,
        favoriteExercisesGymId: favoriteExercisesGymId,
        cachedAt: cachedAt,
      );
    } catch (_) {
      return null;
    }
  }
}

class ProfileCacheStore {
  const ProfileCacheStore();

  static String _key(String userId) => 'profileCache/\$userId';

  Future<ProfileCacheEntry?> read(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return ProfileCacheEntry.fromJson(decoded);
    } catch (_) {
      await prefs.remove(_key(userId));
      return null;
    }
  }

  Future<void> write(String userId, ProfileCacheEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), jsonEncode(entry.toJson()));
  }

  Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }
}
