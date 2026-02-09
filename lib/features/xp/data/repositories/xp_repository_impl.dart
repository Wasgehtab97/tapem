import 'package:tapem/core/logging/elog.dart';

import '../../domain/device_xp_result.dart';
import '../../domain/day_xp_breakdown.dart';
import '../../domain/session_xp_award.dart';
import '../../domain/xp_repository.dart';
import '../sources/firestore_xp_source.dart';

class XpRepositoryImpl implements XpRepository {
  final FirestoreXpSource _source;
  XpRepositoryImpl(this._source);

  @override
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
          sessionDate: sessionDate,
          timeZone: timeZone,
          primaryMuscleGroupIds: primaryMuscleGroupIds,
          secondaryMuscleGroupIds: secondaryMuscleGroupIds,
        )
        .then((result) {
          elogDeviceXp('REPO_RETURN', {
            'result': result.result.name,
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
  Stream<int> watchDayXp({required String userId, required DateTime date}) {
    return _source.watchDayXp(userId: userId, date: date);
  }

  @override
  Stream<DayXpBreakdown> watchDayBreakdown({
    required String userId,
    required DateTime date,
  }) {
    return _source.watchDayBreakdown(userId: userId, date: date);
  }

  @override
  Stream<Map<String, int>> watchMuscleXp({
    required String gymId,
    required String userId,
  }) {
    return _source.watchMuscleXp(gymId: gymId, userId: userId);
  }

  @override
  Stream<Map<String, Map<String, int>>> watchMuscleXpHistory({
    required String gymId,
    required String userId,
  }) {
    return _source.watchMuscleXpHistory(gymId: gymId, userId: userId);
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
  Stream<Map<String, int>> watchDeviceXpBulk({
    required String gymId,
    required String userId,
    required List<String> deviceIds,
  }) {
    return _source.watchDeviceXpBulk(
      gymId: gymId,
      userId: userId,
      deviceIds: deviceIds,
    );
  }

  @override
  Stream<int> watchStatsDailyXp({
    required String gymId,
    required String userId,
  }) {
    return _source.watchStatsDailyXp(gymId: gymId, userId: userId);
  }

  @override
  Future<int> fetchStatsDailyXp({
    required String gymId,
    required String userId,
  }) {
    return _source.fetchStatsDailyXp(gymId: gymId, userId: userId);
  }
}
