import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/rank/data/sources/firestore_rank_source.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';

class FirestoreXpSource {
  final FirebaseFirestore _firestore;
  final FirestoreRankSource _rankSource;

  FirestoreXpSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _rankSource = FirestoreRankSource(firestore: firestore);

  Future<void> addSessionXp({
    required String gymId,
    required String userId,
    required String deviceId,
    required String sessionId,
    required bool showInLeaderboard,
    required bool isMulti,
    required List<String> primaryMuscleGroupIds,
  }) async {
    final now = DateTime.now();
    final dateStr = now.toIso8601String().split('T').first;
    final userRef = _firestore.collection('users').doc(userId);
    final dayRef = userRef.collection('trainingDays').doc(dateStr);
    final muscleRefs = primaryMuscleGroupIds
        .map((id) => userRef.collection('muscles').doc(id))
        .toList();

    await _firestore.runTransaction((tx) async {
      final daySnap = await tx.get(dayRef);
      if (!daySnap.exists) {
        tx.set(dayRef, {'xp': LevelService.xpPerSession});
      }

      for (final ref in muscleRefs) {
        final snap = await tx.get(ref);
        final xp = (snap.data()?['xp'] as int? ?? 0) + LevelService.xpPerSession;
        if (!snap.exists) {
          tx.set(ref, {'xp': xp});
        } else {
          tx.update(ref, {'xp': xp});
        }
      }
    });

    if (!isMulti && showInLeaderboard) {
      await _rankSource.addXp(
        gymId: gymId,
        userId: userId,
        deviceId: deviceId,
        sessionId: sessionId,
        showInLeaderboard: showInLeaderboard,
      );
    }
  }
}
