import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
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
        .map(
          (snap) =>
              snap.docs.map((d) => Challenge.fromMap(d.id, d.data())).toList(),
        );
    final monthly = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('challenges')
        .doc('monthly')
        .collection('items')
        .where('start', isLessThanOrEqualTo: now)
        .where('end', isGreaterThanOrEqualTo: now)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Challenge.fromMap(d.id, d.data())).toList(),
        );

    return StreamZip([
      weekly,
      monthly,
    ]).map((lists) => [...lists[0], ...lists[1]]);
  }

  Stream<List<Badge>> watchBadges(String userId) {
    final col = _firestore.collection('users').doc(userId).collection('badges');
    return col
        .orderBy('awardedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Badge.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<CompletedChallenge>> watchCompletedChallenges(
    String gymId,
    String userId,
  ) {
    final col = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('completedChallenges')
        .orderBy('completedAt', descending: true);
    return col.snapshots().map(
      (snap) =>
          snap.docs
              .map((d) => CompletedChallenge.fromMap(d.id, d.data()))
              .toList(),
    );
  }

  Future<void> checkChallenges({
    required String gymId,
    required String userId,
    required String deviceId,
  }) async {
    final now = Timestamp.fromDate(DateTime.now());
    debugPrint('⏳ checkChallenges gym=$gymId user=$userId device=$deviceId');
    final weeklySnap =
        await _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('challenges')
            .doc('weekly')
            .collection('items')
            .where('start', isLessThanOrEqualTo: now)
            .where('end', isGreaterThanOrEqualTo: now)
            .get();
    final monthlySnap =
        await _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('challenges')
            .doc('monthly')
            .collection('items')
            .where('start', isLessThanOrEqualTo: now)
            .where('end', isGreaterThanOrEqualTo: now)
            .get();
    debugPrint(
      '📥 loaded challenges weekly=${weeklySnap.size} monthly=${monthlySnap.size}',
    );

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
      debugPrint('🔍 required sets for ${ch.id}: ${ch.minSets}');
      try {
        var logCount = 0;
        try {
          if (ch.deviceIds.isEmpty) {
            logCount = await _countSetsViaSessions(
              userId: userId,
              start: ch.start,
              end: ch.end,
            );
          } else {
            for (final ids in _chunkDeviceIds(ch.deviceIds)) {
              logCount += await _countSetsViaSessions(
                userId: userId,
                start: ch.start,
                end: ch.end,
                deviceIds: ids,
              );
            }
          }
        } on FirebaseException catch (e) {
          if (e.code == 'failed-precondition') {
            logCount = await _countSetsViaLogs(
              userId: userId,
              start: ch.start,
              end: ch.end,
              deviceIds: ch.deviceIds.isEmpty ? null : ch.deviceIds,
            );
          } else {
            rethrow;
          }
        }
        debugPrint(
          '📊 logs $logCount / required ${ch.minSets} for challenge ${ch.id}',
        );
        debugPrint('📈 progress $logCount/${ch.minSets} for ${ch.id}');

        if (logCount >= ch.minSets) {
          final completedRef = _firestore
              .collection('gyms')
              .doc(gymId)
              .collection('users')
              .doc(userId)
              .collection('completedChallenges')
              .doc(ch.id);
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

          await _firestore.runTransaction((tx) async {
            // Read all necessary documents first.
            final completedSnap = await tx.get(completedRef);
            final badgeSnap = await tx.get(badgeRef);
            final statsSnap = await tx.get(statsRef);

            if (!completedSnap.exists) {
              // Only write after all reads are done.
              tx.set(completedRef, {
                'challengeId': ch.id,
                'userId': userId,
                'title': ch.title,
                'completedAt': FieldValue.serverTimestamp(),
                'xpReward': ch.xpReward,
              });

              if (!badgeSnap.exists) {
                tx.set(badgeRef, {
                  'challengeId': ch.id,
                  'userId': userId,
                  'awardedAt': FieldValue.serverTimestamp(),
                });
              }

              final data = statsSnap.data() ?? {};
              final previousDaily = data['dailyXP'] as int? ?? 0;
              final challengeXp =
                  (data['challengeXP'] as int? ?? 0) + ch.xpReward;
              final dailyXp = previousDaily + ch.xpReward;
              debugPrint('📊 dailyXP $previousDaily -> $dailyXp');

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
              debugPrint('✅ dailyXP set to $dailyXp');

              debugPrint(
                '🏁 challenge ${ch.id} completed -> +${ch.xpReward} XP (daily=$dailyXp)',
              );
            }
          });
        }
      } on FirebaseException catch (e) {
        debugPrint('🔥 error checking challenge ${ch.id}: ${e.message}');
      }
    }
  }

  Future<int> _countSetsViaSessions({
    required String userId,
    required DateTime start,
    required DateTime end,
    List<String>? deviceIds,
  }) async {
    final startTs = Timestamp.fromDate(start);
    final endTs = Timestamp.fromDate(end);
    Query<Map<String, dynamic>> query = _firestore
        .collectionGroup('sessions')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: startTs)
        .where('createdAt', isLessThanOrEqualTo: endTs);
    if (deviceIds != null && deviceIds.isNotEmpty) {
      query = query.where('deviceId', whereIn: deviceIds);
    }
    final snap = await query.get();
    var total = 0;
    for (final doc in snap.docs) {
      final sets = doc.data()['sets'] as List<dynamic>? ?? const [];
      for (final raw in sets) {
        final map = Map<String, dynamic>.from(raw as Map);
        if (map['done'] == true) {
          total += 1;
        }
      }
    }
    return total;
  }

  Future<int> _countSetsViaLogs({
    required String userId,
    required DateTime start,
    required DateTime end,
    List<String>? deviceIds,
  }) async {
    final startTs = Timestamp.fromDate(start);
    final endTs = Timestamp.fromDate(end);
    if (deviceIds == null || deviceIds.isEmpty) {
      final snap = await _firestore
          .collectionGroup('logs')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startTs)
          .where('timestamp', isLessThanOrEqualTo: endTs)
          .get();
      return snap.size;
    }
    var total = 0;
    for (final ids in _chunkDeviceIds(deviceIds)) {
      final snap = await _firestore
          .collectionGroup('logs')
          .where('userId', isEqualTo: userId)
          .where('deviceId', whereIn: ids)
          .where('timestamp', isGreaterThanOrEqualTo: startTs)
          .where('timestamp', isLessThanOrEqualTo: endTs)
          .get();
      total += snap.size;
    }
    return total;
  }

  Iterable<List<String>> _chunkDeviceIds(List<String> ids, [int size = 10]) sync* {
    if (ids.isEmpty) {
      return;
    }
    for (var i = 0; i < ids.length; i += size) {
      final end = (i + size) > ids.length ? ids.length : i + size;
      yield ids.sublist(i, end);
    }
  }
}
