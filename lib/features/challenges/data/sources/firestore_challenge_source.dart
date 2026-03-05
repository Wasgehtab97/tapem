import 'dart:async';

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

  Future<List<Challenge>> getActiveChallenges(
    String gymId, {
    DateTime? at,
  }) async {
    final now = Timestamp.fromDate(at ?? DateTime.now());
    final challengeSnaps = await _loadActiveChallengeSnapshots(
      gymId: gymId,
      at: now,
    );
    return [
      ...challengeSnaps[0].docs.map((d) => Challenge.fromMap(d.id, d.data())),
      ...challengeSnaps[1].docs.map((d) => Challenge.fromMap(d.id, d.data())),
    ];
  }

  Future<List<Challenge>> getActiveChallengesForUser({
    required String gymId,
    required String userId,
    DateTime? at,
  }) async {
    final activeChallenges = await getActiveChallenges(gymId, at: at);
    if (activeChallenges.isEmpty) {
      return const [];
    }

    final completedIds = await _loadCompletedChallengeIds(
      gymId: gymId,
      userId: userId,
      challengeIds: activeChallenges.map((challenge) => challenge.id),
    );

    return activeChallenges
        .where((challenge) => !completedIds.contains(challenge.id))
        .toList(growable: false);
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
      (snap) => snap.docs
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
    final challengeSnaps = await _loadActiveChallengeSnapshots(
      gymId: gymId,
      at: now,
    );
    final weeklySnap = challengeSnaps[0];
    final monthlySnap = challengeSnaps[1];
    debugPrint(
      '📥 loaded challenges weekly=${weeklySnap.size} monthly=${monthlySnap.size}',
    );

    final challenges = [
      ...weeklySnap.docs.map((d) => Challenge.fromMap(d.id, d.data())),
      ...monthlySnap.docs.map((d) => Challenge.fromMap(d.id, d.data())),
    ];

    debugPrint('🎯 evaluating ${challenges.length} challenges');

    for (final ch in challenges) {
      final targetCount = ch.targetCount;
      if (targetCount <= 0) {
        continue;
      }
      if (!ch.isWorkoutChallenge &&
          ch.deviceIds.isNotEmpty &&
          !ch.deviceIds.contains(deviceId)) {
        continue;
      }
      debugPrint('➡️ check challenge ${ch.id} devices=${ch.deviceIds}');
      debugPrint('🎯 goal type ${ch.goalType.name}, target=$targetCount');
      try {
        final progress = await getChallengeProgress(
          challenge: ch,
          userId: userId,
        );
        debugPrint(
          '📊 progress $progress / required $targetCount for challenge ${ch.id}',
        );

        if (progress >= targetCount) {
          await _completeChallenge(gymId: gymId, userId: userId, challenge: ch);
        }
      } on FirebaseException catch (e) {
        debugPrint('🔥 error checking challenge ${ch.id}: ${e.message}');
      }
    }
  }

  Future<List<QuerySnapshot<Map<String, dynamic>>>>
  _loadActiveChallengeSnapshots({
    required String gymId,
    required Timestamp at,
  }) {
    final weeklyQuery = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('challenges')
        .doc('weekly')
        .collection('items')
        .where('start', isLessThanOrEqualTo: at)
        .where('end', isGreaterThanOrEqualTo: at);
    final monthlyQuery = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('challenges')
        .doc('monthly')
        .collection('items')
        .where('start', isLessThanOrEqualTo: at)
        .where('end', isGreaterThanOrEqualTo: at);
    return Future.wait([weeklyQuery.get(), monthlyQuery.get()]);
  }

  Future<Set<String>> _loadCompletedChallengeIds({
    required String gymId,
    required String userId,
    required Iterable<String> challengeIds,
  }) async {
    final ids = challengeIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (ids.isEmpty) {
      return const <String>{};
    }

    final completedCol = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('completedChallenges');
    final completedIds = <String>{};
    for (var i = 0; i < ids.length; i += 10) {
      final upper = i + 10 > ids.length ? ids.length : i + 10;
      final chunk = ids.sublist(i, upper);
      final snap = await completedCol
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        completedIds.add(doc.id);
      }
    }
    return completedIds;
  }

  Future<int> getChallengeProgress({
    required Challenge challenge,
    required String userId,
  }) async {
    final logs = await _loadLogsForChallenge(
      challenge: challenge,
      userId: userId,
    );
    switch (challenge.goalType) {
      case ChallengeGoalType.deviceSets:
        return logs.length;
      case ChallengeGoalType.workoutDays:
        return _uniqueTrainingDays(logs);
      case ChallengeGoalType.totalReps:
        return logs.fold<int>(0, (total, log) => total + _asInt(log['reps']));
      case ChallengeGoalType.totalVolume:
        return logs.fold<int>(0, (total, log) {
          final reps = _asInt(log['reps']);
          final weight = _asDouble(log['weight']);
          return total + (reps * weight).round();
        });
      case ChallengeGoalType.deviceVariety:
        final uniqueDevices = <String>{};
        for (final log in logs) {
          final id = (log['deviceId'] as String?)?.trim();
          if (id != null && id.isNotEmpty) {
            uniqueDevices.add(id);
          }
        }
        return uniqueDevices.length;
    }
  }

  Future<List<Map<String, dynamic>>> _loadLogsForChallenge({
    required Challenge challenge,
    required String userId,
  }) async {
    if (challenge.deviceIds.isEmpty) {
      final snap = await _firestore
          .collectionGroup('logs')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: challenge.start)
          .where('timestamp', isLessThanOrEqualTo: challenge.end)
          .get();
      return snap.docs.map((doc) => doc.data()).toList(growable: false);
    }

    final chunks = <List<String>>[];
    for (var i = 0; i < challenge.deviceIds.length; i += 10) {
      chunks.add(
        challenge.deviceIds.sublist(
          i,
          i + 10 > challenge.deviceIds.length
              ? challenge.deviceIds.length
              : i + 10,
        ),
      );
    }
    final chunkSnaps = await Future.wait([
      for (final ids in chunks)
        _firestore
            .collectionGroup('logs')
            .where('userId', isEqualTo: userId)
            .where('deviceId', whereIn: ids)
            .where('timestamp', isGreaterThanOrEqualTo: challenge.start)
            .where('timestamp', isLessThanOrEqualTo: challenge.end)
            .get(),
    ]);
    final rows = <Map<String, dynamic>>[];
    for (final snap in chunkSnaps) {
      rows.addAll(snap.docs.map((doc) => doc.data()));
    }
    return rows;
  }

  int _uniqueTrainingDays(List<Map<String, dynamic>> logs) {
    final days = <String>{};
    for (final log in logs) {
      final rawTs = log['timestamp'];
      if (rawTs is Timestamp) {
        final dt = rawTs.toDate().toLocal();
        final dayKey =
            '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        days.add(dayKey);
      }
    }
    return days.length;
  }

  int _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim()) ?? 0;
    return 0;
  }

  double _asDouble(dynamic raw) {
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    if (raw is String) {
      return double.tryParse(raw.replaceAll(',', '.').trim()) ?? 0;
    }
    return 0;
  }

  Future<void> _completeChallenge({
    required String gymId,
    required String userId,
    required Challenge challenge,
  }) async {
    final completedRef = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('completedChallenges')
        .doc(challenge.id);
    final badgeRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('badges')
        .doc(challenge.id);
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
          'challengeId': challenge.id,
          'userId': userId,
          'title': challenge.title,
          'completedAt': FieldValue.serverTimestamp(),
          'xpReward': challenge.xpReward,
        });

        if (!badgeSnap.exists) {
          tx.set(badgeRef, {
            'challengeId': challenge.id,
            'userId': userId,
            'awardedAt': FieldValue.serverTimestamp(),
          });
        }

        final data = statsSnap.data() ?? {};
        final previousDaily = data['dailyXP'] as int? ?? 0;
        final challengeXp =
            (data['challengeXP'] as int? ?? 0) + challenge.xpReward;
        final dailyXp = previousDaily + challenge.xpReward;
        debugPrint('📊 dailyXP $previousDaily -> $dailyXp');

        if (statsSnap.exists) {
          tx.update(statsRef, {'challengeXP': challengeXp, 'dailyXP': dailyXp});
        } else {
          tx.set(statsRef, {'challengeXP': challengeXp, 'dailyXP': dailyXp});
        }
        debugPrint('✅ dailyXP set to $dailyXp');

        debugPrint(
          '🏁 challenge ${challenge.id} completed -> +${challenge.xpReward} XP (daily=$dailyXp)',
        );
      }
    });
  }
}
