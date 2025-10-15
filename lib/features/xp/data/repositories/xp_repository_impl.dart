import 'package:flutter/foundation.dart';

import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/time/logic_day.dart';

import '../../domain/device_xp_result.dart';
import '../../domain/xp_repository.dart';
import '../sources/firestore_xp_source.dart';

class XpRepositoryImpl implements XpRepository {
  final FirestoreXpSource _source;
  XpRepositoryImpl(this._source);

  final Duration _cacheTtl = const Duration(minutes: 2);

  final Map<String, _CacheEntry<Map<String, dynamic>>> _rankStatsCache = {};
  final Map<String, _CacheEntry<Map<String, int>>> _trainingDaysCache = {};
  final Map<String, _CacheEntry<int>> _dayCache = {};
  final Map<String, _CacheEntry<int>> _deviceCache = {};
  final Map<String, _CacheEntry<Map<String, Map<String, int>>>>
      _muscleHistoryCache = {};

  @override
    Future<DeviceXpResult> addSessionXp({
      required String gymId,
      required String userId,
      required String deviceId,
      required String sessionId,
      required bool showInLeaderboard,
      required bool isMulti,
      String? exerciseId,
      required String traceId,
      List<String> primaryMuscleGroupIds = const [],
      List<String> secondaryMuscleGroupIds = const [],
    }) {
      return _source
          .addSessionXp(
        gymId: gymId,
        userId: userId,
        deviceId: deviceId,
        sessionId: sessionId,
        showInLeaderboard: showInLeaderboard,
        isMulti: isMulti,
        exerciseId: exerciseId,
        traceId: traceId,
        primaryMuscleGroupIds: primaryMuscleGroupIds,
        secondaryMuscleGroupIds: secondaryMuscleGroupIds,
      )
          .then((result) {
        elogDeviceXp('REPO_RETURN', {
          'result': result.name,
          'uid': userId,
          'gymId': gymId,
          'deviceId': deviceId,
          'sessionId': sessionId,
          'traceId': traceId,
        });
        return result;
      });
    }

  @override
  Future<int> fetchDayXp({
    required String userId,
    required DateTime date,
    bool forceRemote = false,
  }) async {
    _purgeExpired(_dayCache);
    final dayKey = logicDayKey(date.toUtc());
    final cacheKey = _dayCacheKey(userId, dayKey);

    if (!forceRemote) {
      final cached = _dayCache[cacheKey];
      if (cached != null) {
        debugPrint('♻️ fetchDayXp userId=$userId day=$dayKey (cache)');
        return cached.value;
      }

      _purgeExpired(_trainingDaysCache);
      for (final entry in _trainingDaysCache.entries) {
        if (!entry.key.startsWith('$userId::')) continue;
        final xp = entry.value.value[dayKey];
        if (xp != null) {
          _dayCache[cacheKey] = _CacheEntry(xp, entry.value.timestamp);
          debugPrint('♻️ fetchDayXp userId=$userId day=$dayKey (cache:trainingDays)');
          return xp;
        }
      }
    }

    final xp = await _source.fetchDayXp(userId: userId, date: date);
    final now = DateTime.now();
    _dayCache[cacheKey] = _CacheEntry(xp, now);
    _mergeDayIntoTrainingCache(userId, dayKey, xp, now);
    return xp;
  }

  @override
  Future<Map<String, int>> fetchMuscleXp({
    required String gymId,
    required String userId,
    bool forceRemote = false,
  }) async {
    final stats = await _getRankStats(
      gymId: gymId,
      userId: userId,
      forceRemote: forceRemote,
    );
    if (stats.fromCache) {
      debugPrint('♻️ fetchMuscleXp userId=$userId gymId=$gymId (cache)');
    }

    final map = <String, int>{};
    stats.value.forEach((key, value) {
      if (key.endsWith('XP') && key != 'dailyXP') {
        final group = key.substring(0, key.length - 2);
        map[group] = (value as num?)?.toInt() ?? 0;
      }
    });
    return Map<String, int>.unmodifiable(map);
  }

  @override
  Future<Map<String, Map<String, int>>> fetchMuscleXpHistory({
    required String gymId,
    required String userId,
    int limit = 30,
    bool forceRemote = false,
  }) async {
    final cacheKey = '$gymId::$userId::$limit';
    _purgeExpired(_muscleHistoryCache);
    if (!forceRemote) {
      final cached = _muscleHistoryCache[cacheKey];
      if (cached != null) {
        debugPrint(
            '♻️ fetchMuscleXpHistory userId=$userId gymId=$gymId limit=$limit (cache)');
        return _cloneHistory(cached.value);
      }
    }

    final map = await _source.fetchMuscleXpHistory(
      gymId: gymId,
      userId: userId,
      limit: limit,
    );
    final now = DateTime.now();
    final mutable = {
      for (final entry in map.entries)
        entry.key: Map<String, int>.from(entry.value),
    };
    _muscleHistoryCache[cacheKey] = _CacheEntry(mutable, now);
    return _cloneHistory(mutable);
  }

  @override
  Future<Map<String, int>> fetchTrainingDaysXp(
    String userId, {
    int limit = 30,
    bool forceRemote = false,
  }) async {
    final cacheKey = '$userId::$limit';
    _purgeExpired(_trainingDaysCache);
    _purgeExpired(_dayCache);
    if (!forceRemote) {
      final cached = _trainingDaysCache[cacheKey];
      if (cached != null) {
        debugPrint('♻️ fetchTrainingDaysXp userId=$userId limit=$limit (cache)');
        return Map<String, int>.unmodifiable(Map<String, int>.from(cached.value));
      }
    }

    final map = await _source.fetchTrainingDaysXp(userId, limit: limit);
    final now = DateTime.now();
    final mutable = Map<String, int>.from(map);
    _trainingDaysCache[cacheKey] = _CacheEntry(mutable, now);
    for (final entry in mutable.entries) {
      _dayCache[_dayCacheKey(userId, entry.key)] = _CacheEntry(entry.value, now);
    }
    return Map<String, int>.unmodifiable(Map<String, int>.from(mutable));
  }

  @override
  Future<int> fetchDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
    bool forceRemote = false,
  }) async {
    final cacheKey = '$gymId::$deviceId::$userId';
    _purgeExpired(_deviceCache);
    if (!forceRemote) {
      final cached = _deviceCache[cacheKey];
      if (cached != null) {
        debugPrint(
            '♻️ fetchDeviceXp gymId=$gymId deviceId=$deviceId userId=$userId (cache)');
        return cached.value;
      }
    }

    final xp = await _source.fetchDeviceXp(
      gymId: gymId,
      deviceId: deviceId,
      userId: userId,
    );
    _deviceCache[cacheKey] = _CacheEntry(xp, DateTime.now());
    return xp;
  }

  @override
  Future<int> fetchStatsDailyXp({
    required String gymId,
    required String userId,
    bool forceRemote = false,
  }) async {
    final stats = await _getRankStats(
      gymId: gymId,
      userId: userId,
      forceRemote: forceRemote,
    );
    if (stats.fromCache) {
      debugPrint('♻️ fetchStatsDailyXp gymId=$gymId userId=$userId (cache)');
    }
    final xp = (stats.value['dailyXP'] as num?)?.toInt() ?? 0;
    return xp;
  }

  void _purgeExpired<T>(Map<String, _CacheEntry<T>> cache) {
    final now = DateTime.now();
    cache.removeWhere((_, entry) => now.difference(entry.timestamp) >= _cacheTtl);
  }

  Future<_CacheResult<Map<String, dynamic>>> _getRankStats({
    required String gymId,
    required String userId,
    required bool forceRemote,
  }) async {
    final cacheKey = '$gymId::$userId';
    _purgeExpired(_rankStatsCache);
    if (!forceRemote) {
      final cached = _rankStatsCache[cacheKey];
      if (cached != null) {
        return _CacheResult(
          Map<String, dynamic>.from(cached.value),
          true,
        );
      }
    }

    final raw = await _source.fetchRankStats(
      gymId: gymId,
      userId: userId,
    );
    final now = DateTime.now();
    final mutable = Map<String, dynamic>.from(raw);
    _rankStatsCache[cacheKey] = _CacheEntry(mutable, now);
    return _CacheResult(Map<String, dynamic>.from(mutable), false);
  }

  String _dayCacheKey(String userId, String dayKey) => '$userId::$dayKey';

  void _mergeDayIntoTrainingCache(
    String userId,
    String dayKey,
    int xp,
    DateTime timestamp,
  ) {
    for (final entryKey in _trainingDaysCache.keys.toList()) {
      if (!entryKey.startsWith('$userId::')) continue;
      final existing = _trainingDaysCache[entryKey];
      if (existing == null) continue;
      final updated = Map<String, int>.from(existing.value);
      updated[dayKey] = xp;
      _trainingDaysCache[entryKey] = _CacheEntry(updated, timestamp);
    }
  }

  Map<String, Map<String, int>> _cloneHistory(
      Map<String, Map<String, int>> source) {
    return Map<String, Map<String, int>>.unmodifiable({
      for (final entry in source.entries)
        entry.key:
            Map<String, int>.unmodifiable(Map<String, int>.from(entry.value)),
    });
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime timestamp;
  const _CacheEntry(this.value, this.timestamp);
}

class _CacheResult<T> {
  final T value;
  final bool fromCache;
  const _CacheResult(this.value, this.fromCache);
}
