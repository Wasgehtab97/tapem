import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ProfileCacheStore {
  ProfileCacheStore._();

  static const Duration cacheDuration = Duration(hours: 24);
  static const _prefix = 'profileCache/';
  static const _version = 2;

  static String _key(String userId) => '$_prefix$userId';

  static Future<void> save(
    String userId,
    ProfileCacheEntry entry,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final json = <String, dynamic>{
      'v': _version,
      'cachedAt': entry.cachedAt.toIso8601String(),
      'trainingDates': entry.trainingDates,
      'favoriteAggregates':
          entry.favoriteAggregates.map((e) => e.toJson()).toList(),
      if (entry.lastProcessedAt != null)
        'lastProcessedAt': entry.lastProcessedAt!.toIso8601String(),
    };
    await prefs.setString(_key(userId), jsonEncode(json));
  }

  static Future<ProfileCacheEntry?> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final version = decoded['v'] as int? ?? 0;
      if (version != _version) {
        await prefs.remove(_key(userId));
        return null;
      }
      final cachedAtStr = decoded['cachedAt'] as String?;
      if (cachedAtStr == null) {
        await prefs.remove(_key(userId));
        return null;
      }
      final cachedAt = DateTime.tryParse(cachedAtStr);
      if (cachedAt == null) {
        await prefs.remove(_key(userId));
        return null;
      }
      final trainingDates = <String>[];
      final rawDates = decoded['trainingDates'];
      if (rawDates is List) {
        for (final value in rawDates) {
          if (value is String) {
            trainingDates.add(value);
          }
        }
      }
      final rawFavorites = decoded['favoriteAggregates'];
      final favorites = <FavoriteExerciseAggregateCache>[];
      if (rawFavorites is List) {
        for (final item in rawFavorites) {
          if (item is Map<String, dynamic>) {
            favorites.add(FavoriteExerciseAggregateCache.fromJson(item));
          } else if (item is Map) {
            favorites.add(
              FavoriteExerciseAggregateCache.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
            );
          }
        }
      }
      final lastProcessedAtStr = decoded['lastProcessedAt'] as String?;
      final lastProcessedAt =
          lastProcessedAtStr != null ? DateTime.tryParse(lastProcessedAtStr) : null;
      return ProfileCacheEntry(
        cachedAt: cachedAt,
        trainingDates: trainingDates,
        favoriteAggregates: favorites,
        lastProcessedAt: lastProcessedAt,
      );
    } catch (_) {
      await prefs.remove(_key(userId));
      return null;
    }
  }

  static Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }
}

class ProfileCacheEntry {
  ProfileCacheEntry({
    required this.cachedAt,
    required this.trainingDates,
    required this.favoriteAggregates,
    this.lastProcessedAt,
  });

  final DateTime cachedAt;
  final List<String> trainingDates;
  final List<FavoriteExerciseAggregateCache> favoriteAggregates;
  final DateTime? lastProcessedAt;

  bool get isExpired =>
      DateTime.now().isAfter(cachedAt.add(ProfileCacheStore.cacheDuration));
}

class FavoriteExerciseAggregateCache {
  FavoriteExerciseAggregateCache({
    required this.gymId,
    required this.deviceId,
    this.exerciseId,
    required this.name,
    required this.sessionKeys,
  });

  final String gymId;
  final String deviceId;
  final String? exerciseId;
  final String name;
  final List<String> sessionKeys;

  Map<String, dynamic> toJson() {
    return {
      'gymId': gymId,
      'deviceId': deviceId,
      'exerciseId': exerciseId,
      'name': name,
      'sessionKeys': sessionKeys,
    };
  }

  factory FavoriteExerciseAggregateCache.fromJson(
    Map<String, dynamic> json,
  ) {
    final sessionKeys = <String>[];
    final rawSessions = json['sessionKeys'];
    if (rawSessions is List) {
      for (final value in rawSessions) {
        if (value is String) {
          sessionKeys.add(value);
        }
      }
    }
    return FavoriteExerciseAggregateCache(
      gymId: (json['gymId'] as String?) ?? '',
      deviceId: (json['deviceId'] as String?) ?? '',
      exerciseId: (json['exerciseId'] as String?)?.isEmpty == true
          ? null
          : json['exerciseId'] as String?,
      name: (json['name'] as String?) ?? '',
      sessionKeys: sessionKeys,
    );
  }
}
