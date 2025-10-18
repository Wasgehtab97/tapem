import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/providers/xp_provider.dart';
import 'package:tapem/core/storage/daily_stats_cache_store.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/xp/domain/device_xp_result.dart';
import 'package:tapem/features/xp/domain/xp_repository.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';

class _InMemoryDailyStatsCache implements DailyStatsCache {
  DailyStatsCacheEntry? _entry;

  @override
  Future<void> clear(String gymId, String userId) async {
    _entry = null;
  }

  @override
  Future<DailyStatsCacheEntry?> read(String gymId, String userId) async => _entry;

  @override
  Future<DailyStatsCacheEntry> write(
    String gymId,
    String userId,
    int xp,
    DateTime cachedAt, {
    int? totalXp,
  }) async {
    final entry = DailyStatsCacheEntry(
      xp: xp,
      cachedAt: cachedAt,
      totalXp: totalXp ?? xp,
      dayKey: logicDayKey(cachedAt),
    );
    return _entry = entry;
  }

  @override
  Future<DailyStatsCacheEntry> writeTotal(
    String gymId,
    String userId,
    int totalXp,
    DateTime cachedAt,
  ) async {
    final previous = _entry;
    final dayKey = logicDayKey(cachedAt);
    final prevTotal = previous?.totalXp ?? previous?.xp ?? 0;
    var baseline = prevTotal;
    if (previous != null && previous.dayKey == dayKey) {
      baseline = prevTotal - previous.xp;
      if (previous.totalXp == previous.xp && previous.xp > LevelService.xpPerSession) {
        baseline = prevTotal - LevelService.xpPerSession;
      }
    }
    var dailyXp = totalXp - baseline;
    if (dailyXp < 0) dailyXp = 0;
    if (dailyXp > LevelService.xpPerSession) {
      dailyXp = LevelService.xpPerSession;
    }
    final entry = DailyStatsCacheEntry(
      xp: dailyXp,
      cachedAt: cachedAt,
      totalXp: totalXp,
      dayKey: dayKey,
    );
    return _entry = entry;
  }

  @override
  Future<DailyStatsCacheEntry> increment(
    String gymId,
    String userId,
    int delta,
    DateTime now,
  ) async {
    final previous = _entry;
    final dayKey = logicDayKey(now);
    final prevTotal = previous?.totalXp ?? previous?.xp ?? 0;
    final totalXp = prevTotal + delta;
    final dailyXp = (previous == null || previous.dayKey != dayKey)
        ? delta
        : previous.xp + delta;
    final entry = DailyStatsCacheEntry(
      xp: dailyXp,
      cachedAt: now,
      totalXp: totalXp,
      dayKey: dayKey,
    );
    return _entry = entry;
  }
}

class FakeXpRepository implements XpRepository {
  final dayCtrl = StreamController<int>.broadcast();
  final muscleCtrl = StreamController<Map<String, int>>.broadcast();
  final deviceCtrls = <String, StreamController<int>>{};
  final statsDailyCtrl = StreamController<int>.broadcast();
  int addCalls = 0;
  int statsFetchValue = 0;

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
    }) async {
      addCalls++;
      return DeviceXpResult.okAdded;
    }

  @override
  Stream<int> watchDayXp({required String userId, required DateTime date}) =>
      dayCtrl.stream;

  @override
  Stream<Map<String, int>> watchMuscleXp({
    required String gymId,
    required String userId,
  }) =>
      muscleCtrl.stream;

  @override
  Stream<Map<String, int>> watchTrainingDaysXp(String userId) =>
      const Stream.empty();

  @override
  Stream<int> watchDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
  }) =>
      deviceCtrls
          .putIfAbsent(deviceId, () => StreamController<int>.broadcast())
          .stream;

  @override
  Stream<int> watchStatsDailyXp({
    required String gymId,
    required String userId,
  }) =>
      statsDailyCtrl.stream;

  @override
  Future<int> fetchStatsDailyXp({
    required String gymId,
    required String userId,
  }) async =>
      statsFetchValue;

  void dispose() {
    dayCtrl.close();
    muscleCtrl.close();
    statsDailyCtrl.close();
    for (final c in deviceCtrls.values) {
      c.close();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('XpProvider', () {
    test('addSessionXp delegates to repository', () async {
      final repo = FakeXpRepository();
      final provider = XpProvider(repo: repo);
        await provider.addSessionXp(
          gymId: 'g1',
          userId: 'u1',
          deviceId: 'd1',
          sessionId: 's1',
          showInLeaderboard: false,
          isMulti: false,
          traceId: 't',
        );
      expect(repo.addCalls, 1);
      repo.dispose();
    });

    test('watchDayXp updates dayXp', () async {
      final repo = FakeXpRepository();
      final provider = XpProvider(
        repo: repo,
        statsCache: _InMemoryDailyStatsCache(),
        now: () => DateTime(2024, 1, 1, 12),
      );
      provider.watchDayXp('u1', DateTime(2024, 1, 1));
      repo.dayCtrl.add(15);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.dayXp, 15);
      provider.dispose();
      repo.dispose();
    });

    test('watchMuscleXp updates muscleXp', () async {
      final repo = FakeXpRepository();
      final provider = XpProvider(
        repo: repo,
        statsCache: _InMemoryDailyStatsCache(),
        now: () => DateTime(2024, 1, 1, 12),
      );
      provider.watchMuscleXp('g1', 'u1');
      repo.muscleCtrl.add({'m1': 5});
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.muscleXp, {'m1': 5});
      provider.dispose();
      repo.dispose();
    });

    test('watchDeviceXp tracks multiple devices', () async {
      final repo = FakeXpRepository();
      final provider = XpProvider(
        repo: repo,
        statsCache: _InMemoryDailyStatsCache(),
        now: () => DateTime(2024, 1, 1, 12),
      );
      provider.watchDeviceXp('g1', 'u1', ['d1', 'd2']);
      repo.deviceCtrls['d1']!.add(7);
      repo.deviceCtrls['d2']!.add(3);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.deviceXp, {'d1': 7, 'd2': 3});
      provider.dispose();
      repo.dispose();
    });

    test('watchStatsDailyXp computes level', () async {
      final repo = FakeXpRepository();
      final cache = _InMemoryDailyStatsCache();
      final provider = XpProvider(
        repo: repo,
        statsCache: cache,
        now: () => DateTime(2024, 1, 1, 12),
      );
      repo.statsFetchValue = 1950;
      scheduleMicrotask(() {
        repo.statsDailyCtrl.add(1950);
      });
      await provider.watchStatsDailyXp('g1', 'u1');
      expect(provider.dailyLevel, 2);
      expect(provider.dailyLevelXp, 950);
      // incoming stream update should refresh cache and state
      repo.statsDailyCtrl.add(2050);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.statsDailyXp, 2050);
      final cacheEntry = await cache.read('g1', 'u1');
      expect(cacheEntry, isNotNull);
      expect(cacheEntry!.xp, LevelService.xpPerSession);
      expect(cacheEntry.totalXp, 2050);
      provider.dispose();
      repo.dispose();
    });
  });
}
