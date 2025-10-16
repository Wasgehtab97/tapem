import 'package:tapem/features/rank/data/sources/firestore_rank_source.dart';
import 'package:tapem/features/rank/domain/rank_repository.dart';

class RankRepositoryImpl implements RankRepository {
  final FirestoreRankSource _source;

  RankRepositoryImpl(this._source);

  @override
  Future<void> addXp(
    String gymId,
    String userId,
    String deviceId,
    String sessionId,
    bool showInLeaderboard,
  ) {
    return _source
        .addXp(
          gymId: gymId,
          userId: userId,
          deviceId: deviceId,
          sessionId: sessionId,
          showInLeaderboard: showInLeaderboard,
          isMulti: false,
          traceId: '',
        )
        .then((_) {});
  }

  @override
  Future<List<Map<String, dynamic>>> fetchLeaderboard(
    String gymId,
    String deviceId,
  ) {
    return _source.fetchLeaderboard(gymId, deviceId);
  }

  // Weekly and monthly leaderboards were removed
}
