abstract class XpRepository {
  Future<void> addSessionXp({
    required String gymId,
    required String userId,
    required String deviceId,
    required String sessionId,
    required bool showInLeaderboard,
    required bool isMulti,
    required List<String> primaryMuscleGroupIds,
  });

  Stream<int> watchDayXp({
    required String userId,
    required DateTime date,
  });

  Stream<Map<String, int>> watchMuscleXp(String userId);
}
