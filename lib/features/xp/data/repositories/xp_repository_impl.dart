import '../../domain/xp_repository.dart';
import '../sources/firestore_xp_source.dart';

class XpRepositoryImpl implements XpRepository {
  final FirestoreXpSource _source;
  XpRepositoryImpl(this._source);

  @override
  Future<void> addSessionXp({
    required String gymId,
    required String userId,
    required String deviceId,
    required String sessionId,
    required bool showInLeaderboard,
    required bool isMulti,
    required List<String> primaryMuscleGroupIds,
    required String tz,
  }) {
    return _source.addSessionXp(
      gymId: gymId,
      userId: userId,
      deviceId: deviceId,
      sessionId: sessionId,
      showInLeaderboard: showInLeaderboard,
      isMulti: isMulti,
      primaryMuscleGroupIds: primaryMuscleGroupIds,
      tz: tz,
    );
  }

  @override
  Stream<int> watchDayXp({required String userId, required DateTime date}) {
    return _source.watchDayXp(userId: userId, date: date);
  }

  @override
  Stream<Map<String, int>> watchMuscleXp({
    required String gymId,
    required String userId,
  }) {
    return _source.watchMuscleXp(gymId: gymId, userId: userId);
  }

  @override
  Stream<Map<String, int>> watchTrainingDaysXp(String userId) {
    return _source.watchTrainingDaysXp(userId);
  }

  @override
  Stream<int> watchDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
  }) {
    return _source.watchDeviceXp(
      gymId: gymId,
      deviceId: deviceId,
      userId: userId,
    );
  }

  @override
  Stream<int> watchStatsDailyXp({
    required String gymId,
    required String userId,
  }) {
    return _source.watchStatsDailyXp(gymId: gymId, userId: userId);
  }
}
