import 'device_xp_result.dart';

abstract class XpRepository {
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
  });

  Future<int> fetchDayXp({required String userId, required DateTime date});

  Future<Map<String, int>> fetchMuscleXp({
    required String gymId,
    required String userId,
  });

  Future<Map<String, Map<String, int>>> fetchMuscleXpHistory({
    required String gymId,
    required String userId,
    int limit = 30,
  });

  Future<Map<String, int>> fetchTrainingDaysXp(String userId, {int limit = 30});

  Future<int> fetchDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
  });

  Future<int> fetchStatsDailyXp({
    required String gymId,
    required String userId,
  });
}
