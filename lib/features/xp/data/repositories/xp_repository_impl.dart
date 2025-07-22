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
  }) {
    return _source.addSessionXp(
      gymId: gymId,
      userId: userId,
      deviceId: deviceId,
      sessionId: sessionId,
      showInLeaderboard: showInLeaderboard,
      isMulti: isMulti,
      primaryMuscleGroupIds: primaryMuscleGroupIds,
    );
  }
}
