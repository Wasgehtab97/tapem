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
        .collection('gyms')
        .doc(gymId)
        .collection('challenges')
        .doc('weekly')
        .collection('items')
        .where('start', isLessThanOrEqualTo: now)
        .where('end', isGreaterThanOrEqualTo: now)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Challenge.fromMap(d.id, d.data())).toList());
    final monthly = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('challenges')
        .doc('monthly')
        .collection('items')
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
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('completedChallenges')
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
    debugPrint('⏳ checkChallenges gym=$gymId user=$userId device=$deviceId');
    final weeklySnap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('challenges')
        .doc('weekly')
        .collection('items')
        .where('start', isLessThanOrEqualTo: now)
        .where('end', isGreaterThanOrEqualTo: now)
        .get();
    final monthlySnap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('challenges')
        .doc('monthly')
        .collection('items')
        .where('start', isLessThanOrEqualTo: now)
        .where('end', isGreaterThanOrEqualTo: now)
        .get();
    debugPrint(
        '📥 loaded challenges weekly=${weeklySnap.size} monthly=${monthlySnap.size}');

    final challenges = [
      ...weeklySnap.docs.map((d) => Challenge.fromMap(d.id, d.data())),
      ...monthlySnap.docs.map((d) => Challenge.fromMap(d.id, d.data())),
    ];

    debugPrint('🎯 evaluating ${challenges.length} challenges');

    for (final ch in challenges) {
      if (ch.deviceIds.isNotEmpty && !ch.deviceIds.contains(deviceId)) {
        continue;
      }
      debugPrint('➡️ check challenge ${ch.id} devices=${ch.deviceIds}');
      final deviceIds = ch.deviceIds.isEmpty ? [deviceId] : ch.deviceIds;
      final logsSnap = await _firestore
          .collectionGroup('logs')
          .where('userId', isEqualTo: userId)
          .where('deviceId', whereIn: deviceIds)
          .where('timestamp', isGreaterThanOrEqualTo: ch.start)
          .where('timestamp', isLessThanOrEqualTo: ch.end)
          .get();
      debugPrint(
          '📊 logs ${logsSnap.size} / required ${ch.minSets} for challenge ${ch.id}');

      if (logsSnap.size >= ch.minSets) {
        final completedRef = _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('users')
            .doc(userId)
            .collection('completedChallenges')
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
            final badgeSnap = await tx.get(badgeRef);
            if (!badgeSnap.exists) {
              tx.set(badgeRef, {
                'challengeId': ch.id,
                'userId': userId,
                'awardedAt': FieldValue.serverTimestamp(),
              });
            }
            final statsRef = _firestore
                .collection('gyms')
                .doc(gymId)
                .collection('users')
                .doc(userId)
                .collection('rank')
                .doc('stats');
            final statsSnap = await tx.get(statsRef);
            final data = statsSnap.data() ?? {};
            final challengeXp = (data['challengeXP'] as int? ?? 0) + ch.xpReward;
            final dailyXp = (data['dailyXP'] as int? ?? 0) + ch.xpReward;
            if (statsSnap.exists) {
              tx.update(statsRef, {
                'challengeXP': challengeXp,
                'dailyXP': dailyXp,
              });
            } else {
              tx.set(statsRef, {
                'challengeXP': challengeXp,
                'dailyXP': dailyXp,
              });
            }
            debugPrint(
                '🏁 challenge ${ch.id} completed -> +${ch.xpReward} XP (daily=$dailyXp)');
          }
        });
      }
    }
  }
}
