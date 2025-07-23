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
    final dayRef = userRef.collection('trainingDayXP').doc(dateStr);
    final muscleRefs = primaryMuscleGroupIds
        .map((id) => userRef.collection('muscleGroupXP').doc(id))
        .toList();
    final statsRef = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('rank')
        .doc('stats');

    await _firestore.runTransaction((tx) async {
      final daySnap = await tx.get(dayRef);
      final statsSnap = await tx.get(statsRef);
      final statsData = statsSnap.data() ?? {};

      final updates = <String, dynamic>{};

      final currentDayXp = (daySnap.data()?['xp'] as int?) ?? 0;
      final newDayXp = currentDayXp + LevelService.xpPerSession;
      if (daySnap.exists) {
        tx.update(dayRef, {'xp': newDayXp});
      } else {
        tx.set(dayRef, {'xp': newDayXp});
      }
      updates['dailyXP'] =
          (statsData['dailyXP'] as int? ?? 0) + LevelService.xpPerSession;

      if (!isMulti && muscleRefs.isNotEmpty) {
        for (final ref in muscleRefs) {
          final snap = await tx.get(ref);
          final xp = (snap.data()?['xp'] as int? ?? 0) + LevelService.xpPerSession;
          if (!snap.exists) {
            tx.set(ref, {'xp': xp});
          } else {
            tx.update(ref, {'xp': xp});
          }
        }

        for (final id in primaryMuscleGroupIds) {
          final field = '${id}XP';
          updates[field] =
              (statsData[field] as int? ?? 0) + LevelService.xpPerSession;
        }
      }

      if (updates.isNotEmpty) {
        if (statsSnap.exists) {
          tx.update(statsRef, updates);
        } else {
          tx.set(statsRef, updates);
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

  Stream<int> watchDayXp({
    required String userId,
    required DateTime date,
  }) {
    final dateStr = date.toIso8601String().split('T').first;
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingDayXP')
        .doc(dateStr);
    return ref.snapshots().map((snap) => (snap.data()?['xp'] as int?) ?? 0);
  }

  Stream<Map<String, int>> watchMuscleXp(String userId) {
    final col = _firestore.collection('users').doc(userId).collection('muscleGroupXP');
    return col.snapshots().map((snap) {
      final map = <String, int>{};
      for (final doc in snap.docs) {
        map[doc.id] = (doc.data()['xp'] as int? ?? 0);
      }
      return map;
    });
  }

  Stream<Map<String, int>> watchTrainingDaysXp(String userId) {
    final col = _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingDayXP');
    return col.snapshots().map((snap) {
      final map = <String, int>{};
      for (final doc in snap.docs) {
        map[doc.id] = (doc.data()['xp'] as int? ?? 0);
      }
      return map;
    });
  }

  Stream<int> watchDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
  }) {
    final doc = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('leaderboard')
        .doc(userId);
    return doc.snapshots().map((snap) => (snap.data()?['xp'] as int?) ?? 0);
  }
}
