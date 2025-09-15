import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/logging/xp_trace.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/rank/data/sources/firestore_rank_source.dart';
import 'package:tapem/features/rank/domain/models/level_info.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:tapem/features/xp/domain/device_xp_result.dart';

class FirestoreXpSource {
  final FirebaseFirestore _firestore;
  final FirestoreRankSource _rankSource;

  FirestoreXpSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _rankSource = FirestoreRankSource(firestore: firestore);

      Future<DeviceXpResult> addSessionXp({
        required String gymId,
        required String userId,
        required String deviceId,
        required String sessionId,
        required bool showInLeaderboard,
        required bool isMulti,
        String? exerciseId,
        required String traceId,
      }) async {
        final dayKey = logicDayKey(DateTime.now().toUtc());
        final dateStr = dayKey;
        final userRef = _firestore.collection('users').doc(userId);
        final dayRef = userRef.collection('trainingDayXP').doc(dateStr);
        final statsRef = _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('users')
            .doc(userId)
            .collection('rank')
            .doc('stats');

        XpTrace.log('FS_IN', {
          'gymId': gymId,
          'uid': userId,
          'deviceId': deviceId,
          'sessionId': sessionId,
          'isMulti': isMulti,
          'exerciseId': exerciseId ?? '',
          'dayKey': dayKey,
          'showInLeaderboard': showInLeaderboard,
          'traceId': traceId,
        });
        XpTrace.log('FS_PATHS', {
          'userDayPath': dayRef.path,
          'deviceLbPath':
              _firestore
                  .collection('gyms')
                  .doc(gymId)
                  .collection('devices')
                  .doc(deviceId)
                  .collection('leaderboard')
                  .doc(userId)
                  .path,
          'traceId': traceId,
        });

        try {
          await _firestore.runTransaction((tx) async {
            final daySnap = await tx.get(dayRef);
            final statsSnap = await tx.get(statsRef);
            final statsData = statsSnap.data() ?? {};
            final updates = <String, dynamic>{};

            final currentDayXp = (daySnap.data()?['xp'] as int?) ?? 0;
            final newDayXp = currentDayXp + LevelService.xpPerSession;
            final dayData = {'xp': newDayXp};
            if (daySnap.exists) {
              tx.update(dayRef, dayData);
            } else {
              tx.set(dayRef, dayData);
            }
            if (currentDayXp == 0) {
              updates['dailyXP'] =
                  (statsData['dailyXP'] as int? ?? 0) + LevelService.xpPerSession;
            }

            if (updates.isNotEmpty) {
              if (statsSnap.exists) {
                tx.update(statsRef, updates);
              } else {
                tx.set(statsRef, updates);
              }
            }
          });
        } catch (e) {
          XpTrace.log('FS_OUT', {
            'result': 'error',
            'errMsg': e.toString(),
            'traceId': traceId,
          });
          rethrow;
        }

        final result = await _rankSource.addXp(
          gymId: gymId,
          userId: userId,
          deviceId: deviceId,
          sessionId: sessionId,
          showInLeaderboard: showInLeaderboard,
          isMulti: isMulti,
          exerciseId: exerciseId,
          traceId: traceId,
        );
        XpTrace.log('FS_OUT', {
          'result': result.name,
          'traceId': traceId,
        });
        return result;
      }

  Future<void> removeSessionXp({
    required String gymId,
    required String userId,
    required String deviceId,
    required String sessionId,
    required String dayKey,
    Iterable<String> exerciseIds = const [],
  }) async {
    final uniqueExercises = exerciseIds.where((e) => e.isNotEmpty).toSet();
    final userRef = _firestore.collection('users').doc(userId);
    final dayRef = userRef.collection('trainingDayXP').doc(dayKey);
    final statsRef = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('rank')
        .doc('stats');
    final lbUser = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('leaderboard')
        .doc(userId);
    final lbSess = lbUser.collection('sessions').doc(sessionId);
    final lbDay = lbUser.collection('days').doc(dayKey);
    final exerciseRefs = [
      for (final ex in uniqueExercises)
        lbUser.collection('exercises').doc('$ex-$dayKey'),
    ];

    XpTrace.log('FS_REMOVE_IN', {
      'gymId': gymId,
      'uid': userId,
      'deviceId': deviceId,
      'sessionId': sessionId,
      'dayKey': dayKey,
      'exerciseCount': uniqueExercises.length,
    });

    await _firestore.runTransaction((tx) async {
      final daySnap = await tx.get(dayRef);
      final statsSnap = await tx.get(statsRef);
      final lbUserSnap = await tx.get(lbUser);
      final lbSessSnap = await tx.get(lbSess);
      final lbDaySnap = await tx.get(lbDay);
      final exerciseSnaps = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final ref in exerciseRefs) {
        exerciseSnaps.add(await tx.get(ref));
      }

      const xpDelta = LevelService.xpPerSession;
      var adjustStats = false;

      if (daySnap.exists) {
        final currentDayXp = (daySnap.data()?['xp'] as num?)?.toInt() ?? 0;
        final newDayXp = currentDayXp - xpDelta;
        if (newDayXp > 0) {
          tx.update(dayRef, {'xp': newDayXp});
        } else {
          tx.delete(dayRef);
        }
        adjustStats = currentDayXp > 0 && newDayXp <= 0;
      }

      if (adjustStats && statsSnap.exists) {
        final currentStatsXp = (statsSnap.data()?['dailyXP'] as num?)?.toInt() ?? 0;
        final newStatsXp = currentStatsXp - xpDelta;
        tx.update(statsRef, {'dailyXP': newStatsXp > 0 ? newStatsXp : 0});
      }

      if (lbUserSnap.exists) {
        final info = LevelInfo.fromMap(lbUserSnap.data());
        final updated = LevelService().removeXp(info, xpDelta);
        if (updated.level != info.level || updated.xp != info.xp) {
          tx.update(lbUser, {
            'xp': updated.xp,
            'level': updated.level,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (lbSessSnap.exists) {
        tx.delete(lbSess);
      }
      if (lbDaySnap.exists) {
        tx.delete(lbDay);
      }
      for (final snap in exerciseSnaps) {
        if (snap.exists) {
          tx.delete(snap.reference);
        }
      }
    });

    XpTrace.log('FS_REMOVE_OUT', {
      'gymId': gymId,
      'uid': userId,
      'deviceId': deviceId,
      'sessionId': sessionId,
      'dayKey': dayKey,
    });
  }

    Stream<int> watchDayXp({required String userId, required DateTime date}) {
      final dateStr = logicDayKey(date.toUtc());
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingDayXP')
        .doc(dateStr);
    debugPrint('👀 watchDayXp userId=$userId date=$dateStr');
    return ref.snapshots().map((snap) {
      final xp = (snap.data()?['xp'] as int?) ?? 0;
      debugPrint('📥 dayXp snapshot $xp');
      return xp;
    });
  }

  Stream<Map<String, int>> watchMuscleXp({
    required String gymId,
    required String userId,
  }) {
    final doc = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('rank')
        .doc('stats');
    debugPrint('👀 watchMuscleXp userId=$userId gymId=$gymId');
    return doc.snapshots().map((snap) {
      final data = snap.data() ?? {};
      final map = <String, int>{};
      for (final entry in data.entries) {
        final key = entry.key;
        if (key.endsWith('XP') && key != 'dailyXP') {
          final group = key.substring(0, key.length - 2);
          map[group] = (entry.value as int? ?? 0);
        }
      }
      debugPrint('📥 muscleXp snapshot ${map.length} entries $map');
      return map;
    });
  }

  Stream<Map<String, int>> watchTrainingDaysXp(String userId) {
    final col = _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingDayXP');
    debugPrint('👀 watchTrainingDaysXp userId=$userId');
    return col.snapshots().map((snap) {
      final map = <String, int>{};
      for (final doc in snap.docs) {
        map[doc.id] = (doc.data()['xp'] as int? ?? 0);
      }
      debugPrint('📥 trainingDays snapshot ${map.length} days');
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
    debugPrint(
      '👀 watchDeviceXp gymId=$gymId deviceId=$deviceId userId=$userId',
    );
    return doc.snapshots().map((snap) {
      final xp = (snap.data()?['xp'] as int?) ?? 0;
      debugPrint('📥 deviceXp snapshot $xp');
      return xp;
    });
  }

  Stream<int> watchStatsDailyXp({
    required String gymId,
    required String userId,
  }) {
    final doc = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('rank')
        .doc('stats');
    debugPrint('👀 watchStatsDailyXp gymId=$gymId userId=$userId');
    return doc.snapshots().map((snap) {
      final xp = (snap.data()?['dailyXP'] as int?) ?? 0;
      debugPrint('📥 stats dailyXP snapshot $xp');
      return xp;
    });
  }
}
