abstract class RankRepository {
  Future<void> addXp(
    String gymId,
    String userId,
    String deviceId,
    String sessionId,
    bool showInLeaderboard,
  );

  Stream<List<Map<String, dynamic>>> watchLeaderboard(
    String gymId,
    String deviceId,
  );

  Stream<List<Map<String, dynamic>>> watchWeeklyLeaderboard(
    String gymId,
    String weekId,
  );

  Stream<List<Map<String, dynamic>>> watchMonthlyLeaderboard(
    String gymId,
    String monthId,
  );
}
