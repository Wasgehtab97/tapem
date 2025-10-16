abstract class RankRepository {
  Future<void> addXp(
    String gymId,
    String userId,
    String deviceId,
    String sessionId,
    bool showInLeaderboard,
  );

  Future<List<Map<String, dynamic>>> fetchLeaderboard(
    String gymId,
    String deviceId,
  );
}
