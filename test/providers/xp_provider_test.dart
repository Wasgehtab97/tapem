import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/providers/xp_provider.dart';
import 'package:tapem/features/xp/domain/xp_repository.dart';
import 'package:tapem/features/xp/domain/device_xp_result.dart';

class FakeXpRepository implements XpRepository {
  final dayCtrl = StreamController<int>.broadcast();
  final muscleCtrl = StreamController<Map<String, int>>.broadcast();
  final deviceCtrls = <String, StreamController<int>>{};
  int addCalls = 0;

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
      const Stream.empty();

  void dispose() {
    dayCtrl.close();
    muscleCtrl.close();
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
      final provider = XpProvider(repo: repo);
      provider.watchDayXp('u1', DateTime(2024, 1, 1));
      repo.dayCtrl.add(15);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.dayXp, 15);
      provider.dispose();
      repo.dispose();
    });

    test('watchMuscleXp updates muscleXp', () async {
      final repo = FakeXpRepository();
      final provider = XpProvider(repo: repo);
      provider.watchMuscleXp('g1', 'u1');
      repo.muscleCtrl.add({'m1': 5});
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.muscleXp, {'m1': 5});
      provider.dispose();
      repo.dispose();
    });

    test('watchDeviceXp tracks multiple devices', () async {
      final repo = FakeXpRepository();
      final provider = XpProvider(repo: repo);
      provider.watchDeviceXp('g1', 'u1', ['d1', 'd2']);
      repo.deviceCtrls['d1']!.add(7);
      repo.deviceCtrls['d2']!.add(3);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.deviceXp, {'d1': 7, 'd2': 3});
      provider.dispose();
      repo.dispose();
    });
  });
}
