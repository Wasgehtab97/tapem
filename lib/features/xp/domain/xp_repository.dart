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
  });

  Stream<int> watchDayXp({required String userId, required DateTime date});

  Stream<Map<String, int>> watchMuscleXp({
    required String gymId,
    required String userId,
  });

  Stream<Map<String, int>> watchTrainingDaysXp(String userId);

  Stream<int> watchDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
  });

  Stream<int> watchStatsDailyXp({
    required String gymId,
    required String userId,
  });
}
