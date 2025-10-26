import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/logging/xp_trace.dart';
import 'package:tapem/core/storage/daily_stats_cache_store.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:tapem/features/xp/data/repositories/xp_repository_impl.dart';
import 'package:tapem/features/xp/data/sources/firestore_xp_source.dart';
import 'package:tapem/features/xp/domain/device_xp_result.dart';
import 'package:tapem/features/xp/domain/xp_repository.dart';

class XpProvider extends ChangeNotifier {
  final XpRepository _repo;
  final DailyStatsCache _statsCache;
  final DateTime Function() _now;

  XpProvider({
    XpRepository? repo,
    DailyStatsCache? statsCache,
    DateTime Function()? now,
  })  : _repo = repo ?? XpRepositoryImpl(FirestoreXpSource()),
        _statsCache = statsCache ?? const DailyStatsCacheStore(),
        _now = now ?? DateTime.now;

  Map<String, int> _muscleXp = {};
  int _dayXp = 0;
  StreamSubscription<int>? _daySub;
  StreamSubscription<Map<String, int>>? _muscleSub;
  StreamSubscription<Map<String, Map<String, int>>>? _muscleDailySub;
  Map<String, int> _dayListXp = {};
  final Map<String, int> _deviceXp = {};
  StreamSubscription<Map<String, int>>? _dayListSub;
  final Map<String, StreamSubscription<int>> _deviceSubs = {};
  int _statsDailyXp = 0;
  int _dailyLevel = 1;
  int _dailyLevelXp = 0;
  StreamSubscription<int>? _statsDailySub;
  DateTime? _statsDailyFetchedAt;
  Map<String, Map<String, int>> _muscleDailyXp = {};

  Map<String, int> get muscleXp => _muscleXp;
  int get dayXp => _dayXp;
  Map<String, int> get dayListXp => _dayListXp;
  Map<String, int> get deviceXp => _deviceXp;
  int get statsDailyXp => _statsDailyXp;
  int get dailyLevel => _dailyLevel;
  int get dailyLevelXp => _dailyLevelXp;
  Map<String, Map<String, int>> get muscleDailyXp => _muscleDailyXp;
  double get dailyProgress =>
      _dailyLevel >= LevelService.maxLevel
          ? 1
          : _dailyLevelXp / LevelService.xpPerLevel;

  bool _isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _applyDailyStats({
    required int totalXp,
    required DateTime fetchedAt,
    required String source,
  }) {
    final previousXp = _statsDailyXp;
    final previousDate = _statsDailyFetchedAt;
    _statsDailyXp = totalXp;
    _statsDailyFetchedAt = fetchedAt;
    var level = (totalXp ~/ LevelService.xpPerLevel) + 1;
    if (level > LevelService.maxLevel) level = LevelService.maxLevel;
    final xpInLevel =
        level >= LevelService.maxLevel ? 0 : totalXp % LevelService.xpPerLevel;
    final shouldNotify =
        previousXp != totalXp ||
        previousDate == null ||
        !_isSameCalendarDay(previousDate, fetchedAt);
    _dailyLevel = level;
    _dailyLevelXp = xpInLevel;
    debugPrint(
        '🔄 provider statsDailyXp=$totalXp level=$_dailyLevel xpInLevel=$_dailyLevelXp source=$source');
    if (shouldNotify) {
      notifyListeners();
    }
  }

  Future<DeviceXpResult> addSessionXp({
    required String gymId,
    required String userId,
    required String deviceId,
    required String sessionId,
    required bool showInLeaderboard,
    required bool isMulti,
    String? exerciseId,
    required String traceId,
    required DateTime sessionDate,
    required String timeZone,
    List<String> primaryMuscleGroupIds = const [],
    List<String> secondaryMuscleGroupIds = const [],
  }) async {
    assert(LevelService.xpPerSession == 50);
    XpTrace.log('PROVIDER_IN', {
      'gymId': gymId,
      'uid': userId,
      'deviceId': deviceId,
      'sessionId': sessionId,
      'isMulti': isMulti,
      'exerciseId': exerciseId ?? '',
      'showInLeaderboard': showInLeaderboard,
      'traceId': traceId,
    });
    if (deviceId.isEmpty) {
      XpTrace.log('SKIP', {
        'reason': 'noDevice',
        'traceId': traceId,
      });
      return DeviceXpResult.skipNoDevice;
    }
    try {
      final award = await _repo.addSessionXp(
        gymId: gymId,
        userId: userId,
        deviceId: deviceId,
        sessionId: sessionId,
        showInLeaderboard: showInLeaderboard,
        isMulti: isMulti,
        exerciseId: exerciseId,
        traceId: traceId,
        sessionDate: sessionDate,
        timeZone: timeZone,
        primaryMuscleGroupIds: primaryMuscleGroupIds,
        secondaryMuscleGroupIds: secondaryMuscleGroupIds,
      );
      final result = award.result;
      XpTrace.log('PROVIDER_OUT', {
        'result': result.name,
        'deltaXp': award.xpDelta,
        'dayXp': award.dayXp,
        'updatedLocalCache': (result == DeviceXpResult.okAdded ||
            result == DeviceXpResult.okAddedNoLeaderboard) &&
            (award.totalXp != null),
        'traceId': traceId,
      });
      if (result == DeviceXpResult.okAdded ||
          result == DeviceXpResult.okAddedNoLeaderboard) {
        _deviceXp[deviceId] =
            (_deviceXp[deviceId] ?? 0) + LevelService.xpPerSession;
        XpTrace.log('CACHE_BUMP', {
          'deviceId': deviceId,
          'newXp': _deviceXp[deviceId],
          'traceId': traceId,
        });
        notifyListeners();
        if (award.totalXp != null) {
          try {
            final entry = await _statsCache.writeTotal(
              gymId,
              userId,
              award.totalXp!,
              _now(),
              dayXp: award.dayXp,
              components: award.components,
              penalties: award.penalties,
            );
            _applyDailyStats(
              totalXp: entry.totalXp,
              fetchedAt: entry.cachedAt,
              source: 'localWrite',
            );
          } catch (e, st) {
            elogError('XP_STATS_CACHE_WRITE_FAILED', e, st, {
              'gymId': gymId,
              'uid': userId,
            });
          }
        }
      }
      return result;
    } catch (e, st) {
      XpTrace.log('PROVIDER_OUT', {
        'result': 'error',
        'err': e.toString(),
        'traceId': traceId,
      });
      elogError('XP_ADD_UNEXPECTED', e, st, {
        'uid': userId,
        'gymId': gymId,
        'deviceId': deviceId,
        'sessionId': sessionId,
      });
      return DeviceXpResult.error;
    }
  }

  void watchDayXp(String userId, DateTime date) {
    debugPrint('👀 provider watchDayXp userId=$userId date=$date');
    _daySub?.cancel();
    _daySub = _repo.watchDayXp(userId: userId, date: date).listen((value) {
      _dayXp = value;
      debugPrint('🔄 provider dayXp=$value');
      notifyListeners();
    });
  }

  void watchMuscleXp(String gymId, String userId) {
    debugPrint('👀 provider watchMuscleXp userId=$userId gymId=$gymId');
    _muscleSub?.cancel();
    _muscleSub = _repo.watchMuscleXp(gymId: gymId, userId: userId).listen((
      map,
    ) {
      _muscleXp = map;
      debugPrint('🔄 provider muscleXp=${map.length} entries $map');
      notifyListeners();
    });
  }

  void watchMuscleDailyXp(String gymId, String userId) {
    debugPrint('👀 provider watchMuscleDailyXp userId=$userId gymId=$gymId');
    _muscleDailySub?.cancel();
    _muscleDailySub = _repo
        .watchMuscleXpHistory(gymId: gymId, userId: userId)
        .listen((map) {
      _muscleDailyXp = map;
      debugPrint('🔄 provider muscleDailyXp=${map.length} days');
      notifyListeners();
    });
  }

  void watchTrainingDays(String userId) {
    debugPrint('👀 provider watchTrainingDays userId=$userId');
    _dayListSub?.cancel();
    _dayListSub = _repo.watchTrainingDaysXp(userId).listen((map) {
      _dayListXp = map;
      debugPrint('🔄 provider dayListXp=${map.length} days');
      notifyListeners();
    });
  }

  void watchDeviceXp(String gymId, String userId, List<String> deviceIds) {
    XpTrace.log('WATCH_INIT', {
      'deviceCountBeforeAttach': _deviceSubs.length,
      'gymId': gymId,
      'uid': userId,
    });
    final detached = <String>[];
    for (final id in _deviceSubs.keys.toList()) {
      if (!deviceIds.contains(id)) {
        _deviceSubs[id]?.cancel();
        _deviceSubs.remove(id);
        _deviceXp.remove(id);
        detached.add(id);
      }
    }
    final attached = <String>[];
    for (final id in deviceIds) {
      if (_deviceSubs.containsKey(id)) continue;
      attached.add(id);
      _deviceSubs[id] = _repo
          .watchDeviceXp(gymId: gymId, deviceId: id, userId: userId)
          .listen((xp) {
            _deviceXp[id] = xp;
            final level = xp ~/ LevelService.xpPerLevel + 1;
            XpTrace.log('WATCH_UPDATE', {
              'deviceId': id,
              'xp': xp,
              'level': level,
            });
            notifyListeners();
          });
    }
    if (attached.isNotEmpty || detached.isNotEmpty) {
      XpTrace.log('WATCH_ATTACH', {
        'attached': attached,
        'detached': detached,
      });
    }
  }

  Future<void> watchStatsDailyXp(
    String gymId,
    String userId, {
    bool forceRefresh = false,
  }) async {
    debugPrint('👀 provider watchStatsDailyXp gymId=$gymId userId=$userId');
    await _statsDailySub?.cancel();
    _statsDailySub = null;
    final now = _now();
    DailyStatsCacheEntry? cacheEntry;
    try {
      cacheEntry = await _statsCache.read(gymId, userId);
    } catch (e, st) {
      elogError('XP_STATS_CACHE_READ_FAILED', e, st, {
        'gymId': gymId,
        'uid': userId,
      });
    }
    Future<void> fetchAndApply(String source) async {
      try {
        final xp = await _repo.fetchStatsDailyXp(
          gymId: gymId,
          userId: userId,
        );
        final saved = await _statsCache.writeTotal(gymId, userId, xp, _now());
        _applyDailyStats(
          totalXp: saved.totalXp,
          fetchedAt: saved.cachedAt,
          source: source,
        );
      } catch (e, st) {
        elogError('XP_STATS_FETCH_FAILED', e, st, {
          'gymId': gymId,
          'uid': userId,
        });
      }
    }

    final initialCompleter = Completer<void>();
    var hasInitialStreamValue = false;
    _statsDailySub = _repo
        .watchStatsDailyXp(gymId: gymId, userId: userId)
        .listen((xp) async {
      try {
        final saved = await _statsCache.writeTotal(gymId, userId, xp, _now());
        _applyDailyStats(
          totalXp: saved.totalXp,
          fetchedAt: saved.cachedAt,
          source: 'stream',
        );
      } catch (e, st) {
        elogError('XP_STATS_CACHE_WRITE_FAILED', e, st, {
          'gymId': gymId,
          'uid': userId,
        });
      } finally {
        if (!hasInitialStreamValue) {
          hasInitialStreamValue = true;
          if (!initialCompleter.isCompleted) {
            initialCompleter.complete();
          }
        }
      }
    }, onError: (Object error, StackTrace st) {
      elogError('XP_STATS_STREAM_FAILED', error, st, {
        'gymId': gymId,
        'uid': userId,
      });
      if (!initialCompleter.isCompleted) {
        initialCompleter.completeError(error, st);
      }
    });

    if (!forceRefresh && cacheEntry != null && cacheEntry.isSameCalendarDay(now)) {
      _applyDailyStats(
        totalXp: cacheEntry.totalXp,
        fetchedAt: cacheEntry.cachedAt,
        source: 'cache',
      );
      debugPrint('💾 statsDailyXp cache hit -> using stream for updates');
      return;
    }

    try {
      await initialCompleter.future.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      debugPrint('⏱ statsDailyXp initial stream timeout -> fallback fetch');
      await fetchAndApply('fetch');
    } catch (_) {
      await fetchAndApply('fetch');
    }
  }

  @override
  void dispose() {
    _daySub?.cancel();
    _muscleSub?.cancel();
    _muscleDailySub?.cancel();
    _dayListSub?.cancel();
    _statsDailySub?.cancel();
    for (final sub in _deviceSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
