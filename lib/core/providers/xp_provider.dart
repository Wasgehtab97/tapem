import 'package:flutter/foundation.dart';
import 'package:tapem/features/xp/domain/xp_repository.dart';
import 'package:tapem/features/xp/data/sources/firestore_xp_source.dart';
import 'package:tapem/features/xp/data/repositories/xp_repository_impl.dart';

class XpProvider extends ChangeNotifier {
  final XpRepository _repo;
  XpProvider({XpRepository? repo})
      : _repo = repo ?? XpRepositoryImpl(FirestoreXpSource());

  Future<void> addSessionXp({
    required String gymId,
    required String userId,
    required String deviceId,
    required String sessionId,
    required bool showInLeaderboard,
    required bool isMulti,
    required List<String> primaryMuscleGroupIds,
  }) {
    return _repo.addSessionXp(
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
