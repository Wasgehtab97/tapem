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
