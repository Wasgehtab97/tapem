import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';
import '../../domain/models/challenge.dart';
import '../../domain/models/badge.dart';
import '../../domain/models/completed_challenge.dart';

class FirestoreChallengeSource {
  final FirebaseFirestore _firestore;

  FirestoreChallengeSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<Challenge>> watchActiveChallenges(String gymId) {
    final now = Timestamp.fromDate(DateTime.now());
    final weekly = _firestore
        .collection('gyms/$gymId/challenges/weekly')
        .where('start', isLessThanOrEqualTo: now)
        .where('end', isGreaterThanOrEqualTo: now)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Challenge.fromMap(d.id, d.data())).toList());
    final monthly = _firestore
        .collection('gyms/$gymId/challenges/monthly')
        .where('start', isLessThanOrEqualTo: now)
        .where('end', isGreaterThanOrEqualTo: now)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Challenge.fromMap(d.id, d.data())).toList());

    return StreamZip([weekly, monthly])
        .map((lists) => [...lists[0], ...lists[1]]);
  }

  Stream<List<Badge>> watchBadges(String userId) {
    final col = _firestore.collection('users').doc(userId).collection('badges');
    return col
        .orderBy('awardedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Badge.fromMap(d.id, d.data())).toList());
  }

  Stream<List<CompletedChallenge>> watchCompletedChallenges(
      String gymId, String userId) {
    final col = _firestore
        .collection('gyms/$gymId/users/$userId/completedChallenges')
        .orderBy('completedAt', descending: true);
    return col.snapshots().map((snap) => snap.docs
        .map((d) => CompletedChallenge.fromMap(d.id, d.data()))
        .toList());
  }

  Future<void> checkChallenges({
    required String gymId,
    required String userId,
    required String deviceId,
  }) async {
    final now = Timestamp.fromDate(DateTime.now());
    final weeklySnap = await _firestore
        .collection('gyms/$gymId/challenges/weekly')
        .where('start', isLessThanOrEqualTo: now)
        .where('end', isGreaterThanOrEqualTo: now)
        .get();
    final monthlySnap = await _firestore
        .collection('gyms/$gymId/challenges/monthly')
        .where('start', isLessThanOrEqualTo: now)
        .where('end', isGreaterThanOrEqualTo: now)
        .get();

    final challenges = [
      ...weeklySnap.docs.map((d) => Challenge.fromMap(d.id, d.data())),
      ...monthlySnap.docs.map((d) => Challenge.fromMap(d.id, d.data())),
    ];

    for (final ch in challenges) {
      if (ch.deviceIds.isNotEmpty && !ch.deviceIds.contains(deviceId)) {
        continue;
      }
      final deviceIds = ch.deviceIds.isEmpty ? [deviceId] : ch.deviceIds;
      final logsSnap = await _firestore
          .collectionGroup('logs')
          .where('userId', isEqualTo: userId)
          .where('deviceId', whereIn: deviceIds)
          .where('timestamp', isGreaterThanOrEqualTo: ch.start)
          .where('timestamp', isLessThanOrEqualTo: ch.end)
          .get();

      if (logsSnap.size >= ch.minSets) {
        final completedRef = _firestore
            .collection('gyms/$gymId/users/$userId/completedChallenges')
            .doc(ch.id);
        await _firestore.runTransaction((tx) async {
          final completedSnap = await tx.get(completedRef);
          if (!completedSnap.exists) {
            tx.set(completedRef, {
              'challengeId': ch.id,
              'userId': userId,
              'title': ch.title,
              'completedAt': FieldValue.serverTimestamp(),
              'xpReward': ch.xpReward,
            });
            final badgeRef = _firestore
                .collection('users')
                .doc(userId)
                .collection('badges')
                .doc(ch.id);
            final statsRef = _firestore
                .collection('gyms')
                .doc(gymId)
                .collection('users')
                .doc(userId)
                .collection('rank')
                .doc('stats');
            final statsSnap = await tx.get(statsRef);
            final xp = (statsSnap.data()?['challengeXP'] as int? ?? 0) + ch.xpReward;
            if (statsSnap.exists) {
              tx.update(statsRef, {'challengeXP': xp});
            } else {
              tx.set(statsRef, {'challengeXP': xp});
            }
            tx.set(badgeRef, {
              'challengeId': ch.id,
              'userId': userId,
              'awardedAt': FieldValue.serverTimestamp(),
            });
          }
        });
      }
    }
  }
}
