abstract class RankRepository {
  Future<void> addXp(
    String gymId,
    String userId,
    String deviceId,
    bool showInLeaderboard,
  );
  Stream<List<Map<String, dynamic>>> watchLeaderboard(String gymId);
}
