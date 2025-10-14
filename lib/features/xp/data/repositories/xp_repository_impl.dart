import '../../domain/xp_repository.dart';
import '../../domain/device_xp_result.dart';
import '../sources/firestore_xp_source.dart';
import 'package:tapem/core/logging/elog.dart';

class XpRepositoryImpl implements XpRepository {
  final FirestoreXpSource _source;
  XpRepositoryImpl(this._source);

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
    }) {
      return _source
          .addSessionXp(
        gymId: gymId,
        userId: userId,
        deviceId: deviceId,
        sessionId: sessionId,
        showInLeaderboard: showInLeaderboard,
        isMulti: isMulti,
        exerciseId: exerciseId,
        traceId: traceId,
        primaryMuscleGroupIds: primaryMuscleGroupIds,
        secondaryMuscleGroupIds: secondaryMuscleGroupIds,
      )
          .then((result) {
        elogDeviceXp('REPO_RETURN', {
          'result': result.name,
          'uid': userId,
          'gymId': gymId,
          'deviceId': deviceId,
          'sessionId': sessionId,
          'traceId': traceId,
        });
        return result;
      });
    }

  @override
  Future<int> fetchDayXp({required String userId, required DateTime date}) {
    return _source.fetchDayXp(userId: userId, date: date);
  }

  @override
  Future<Map<String, int>> fetchMuscleXp({
    required String gymId,
    required String userId,
  }) {
    return _source.fetchMuscleXp(gymId: gymId, userId: userId);
  }

  @override
  Future<Map<String, Map<String, int>>> fetchMuscleXpHistory({
    required String gymId,
    required String userId,
    int limit = 30,
  }) {
    return _source.fetchMuscleXpHistory(
      gymId: gymId,
      userId: userId,
      limit: limit,
    );
  }

  @override
  Future<Map<String, int>> fetchTrainingDaysXp(
    String userId, {
    int limit = 30,
  }) {
    return _source.fetchTrainingDaysXp(userId, limit: limit);
  }

  @override
  Future<int> fetchDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
  }) {
    return _source.fetchDeviceXp(
      gymId: gymId,
      deviceId: deviceId,
      userId: userId,
    );
  }

  @override
  Future<int> fetchStatsDailyXp({
    required String gymId,
    required String userId,
  }) {
    return _source.fetchStatsDailyXp(gymId: gymId, userId: userId);
  }
}
