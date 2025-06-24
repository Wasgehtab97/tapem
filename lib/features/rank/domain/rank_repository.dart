abstract class RankRepository {
  Future<void> addXp(String gymId, String userId, String deviceId);
  Stream<List<Map<String, dynamic>>> watchLeaderboard(String gymId);
}
