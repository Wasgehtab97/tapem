// lib/features/rank/data/repositories/rank_repository_impl.dart

import '../device_xp.dart';
import '../sources/firestore_rank_source.dart';

class RankRepositoryImpl {
  final FirestoreRankSource _source;
  RankRepositoryImpl(this._source);

  Future<DeviceXp?> getUserXp({
    required String gymId,
    required String deviceId,
    required String userId,
  }) {
    return _source.getUserXp(
      gymId: gymId,
      deviceId: deviceId,
      userId: userId,
    );
  }

  Future<void> updateUserXp({
    required String gymId,
    required String deviceId,
    required String userId,
    required int increment,
  }) {
    return _source.updateUserXp(
      gymId: gymId,
      deviceId: deviceId,
      userId: userId,
      increment: increment,
    );
  }

  Future<List<MapEntry<String, DeviceXp>>> getLeaderboard({
    required String gymId,
    required String deviceId,
  }) {
    return _source.getLeaderboard(gymId: gymId, deviceId: deviceId);
  }
}
