import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/providers/xp_provider.dart';
import 'package:tapem/features/xp/domain/xp_repository.dart';
import 'package:tapem/features/xp/domain/device_xp_result.dart';

class FakeXpRepository implements XpRepository {
  int addCalls = 0;
  int dayXp = 0;
  Map<String, int> muscleXp = {};
  Map<String, Map<String, int>> muscleHistory = {};
  Map<String, int> trainingDays = {};
  final Map<String, int> deviceXp = {};
  int statsDailyXp = 0;
  final List<String> requestedDevices = [];

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
  Future<int> fetchDayXp({
    required String userId,
    required DateTime date,
    bool forceRemote = false,
  }) async {
    return dayXp;
  }

  @override
  Future<Map<String, int>> fetchMuscleXp({
    required String gymId,
    required String userId,
    bool forceRemote = false,
  }) async {
    return muscleXp;
  }

  @override
  Future<Map<String, Map<String, int>>> fetchMuscleXpHistory({
    required String gymId,
    required String userId,
    int limit = 30,
    bool forceRemote = false,
  }) async {
    return muscleHistory;
  }

  @override
  Future<Map<String, int>> fetchTrainingDaysXp(
    String userId, {
    int limit = 30,
    bool forceRemote = false,
  }) async {
    return trainingDays;
  }

  @override
  Future<int> fetchDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
    bool forceRemote = false,
  }) async {
    requestedDevices.add(deviceId);
    return deviceXp[deviceId] ?? 0;
  }

  @override
  Future<int> fetchStatsDailyXp({
    required String gymId,
    required String userId,
    bool forceRemote = false,
  }) async {
    return statsDailyXp;
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
    });

    test('watchDayXp updates dayXp', () async {
      final repo = FakeXpRepository();
      final provider = XpProvider(repo: repo);
      repo.dayXp = 15;
      provider.watchDayXp('u1', DateTime(2024, 1, 1));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(provider.dayXp, 15);
      provider.dispose();
    });

    test('watchMuscleXp updates muscleXp', () async {
      final repo = FakeXpRepository();
      final provider = XpProvider(repo: repo);
      repo.muscleXp = {'m1': 5};
      provider.watchMuscleXp('g1', 'u1');
      await Future.delayed(const Duration(milliseconds: 20));
      expect(provider.muscleXp, {'m1': 5});
      provider.dispose();
    });

    test('watchDeviceXp tracks multiple devices', () async {
      final repo = FakeXpRepository();
      final provider = XpProvider(repo: repo);
      repo.deviceXp['d1'] = 7;
      repo.deviceXp['d2'] = 3;
      provider.watchDeviceXp('g1', 'u1', ['d1', 'd2']);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.deviceXp, {'d1': 7, 'd2': 3});
      expect(repo.requestedDevices, containsAll(['d1', 'd2']));
      provider.dispose();
    });

    test('watchStatsDailyXp computes level', () async {
      final repo = FakeXpRepository();
      final provider = XpProvider(repo: repo);
      repo.statsDailyXp = 1950; // level 2, xp 950
      provider.watchStatsDailyXp('g1', 'u1');
      await Future.delayed(const Duration(milliseconds: 20));
      expect(provider.dailyLevel, 2);
      expect(provider.dailyLevelXp, 950);
      provider.dispose();
    });
  });
}
