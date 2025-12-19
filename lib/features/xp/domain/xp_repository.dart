import 'session_xp_award.dart';

abstract class XpRepository {
  Future<SessionXpAward> addSessionXp({
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
  });

  Stream<int> watchDayXp({required String userId, required DateTime date});

  Stream<Map<String, int>> watchMuscleXp({
    required String gymId,
    required String userId,
  });

  Stream<Map<String, Map<String, int>>> watchMuscleXpHistory({
    required String gymId,
    required String userId,
  });

  Stream<Map<String, int>> watchTrainingDaysXp(String userId);

  Stream<int> watchDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
  });

  Stream<Map<String, int>> watchDeviceXpBulk({
    required String gymId,
    required String userId,
    required List<String> deviceIds,
  });

  Stream<int> watchStatsDailyXp({
    required String gymId,
    required String userId,
  });

  Future<int> fetchStatsDailyXp({
    required String gymId,
    required String userId,
  });
}
