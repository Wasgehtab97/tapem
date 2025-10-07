import 'dart:async';

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
        List<String> primaryMuscleGroupIds = const [],
        List<String> secondaryMuscleGroupIds = const [],
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
          await _runTransactionWithRetry<void>(
            (tx) async {
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
            },
            traceId: traceId,
            logPrefix: 'FS',
          );
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
        if (result == DeviceXpResult.okAdded ||
            result == DeviceXpResult.okAddedNoLeaderboard) {
          await _applyMuscleXp(
            statsRef: statsRef,
            primaryMuscleGroupIds: primaryMuscleGroupIds,
            secondaryMuscleGroupIds: secondaryMuscleGroupIds,
            traceId: traceId,
          );
        }
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
    List<String> primaryMuscleGroupIds = const [],
    List<String> secondaryMuscleGroupIds = const [],
  }) async {
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

    XpTrace.log('FS_REMOVE_IN', {
      'gymId': gymId,
      'uid': userId,
      'deviceId': deviceId,
      'sessionId': sessionId,
      'dayKey': dayKey,
      'exerciseCount': exerciseIds.where((e) => e.isNotEmpty).length,
    });

    await _firestore.runTransaction((tx) async {
      final daySnap = await tx.get(dayRef);
      final statsSnap = await tx.get(statsRef);
      final lbUserSnap = await tx.get(lbUser);
      final lbSessSnap = await tx.get(lbSess);
      final lbDaySnap = await tx.get(lbDay);

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
    });

    XpTrace.log('FS_REMOVE_OUT', {
      'gymId': gymId,
      'uid': userId,
      'deviceId': deviceId,
      'sessionId': sessionId,
      'dayKey': dayKey,
    });

    final delta = _buildMuscleXpDelta(
      primaryMuscleGroupIds,
      secondaryMuscleGroupIds,
    );
    if (delta.isNotEmpty) {
      final updates = <String, dynamic>{};
      delta.forEach((key, value) {
        updates['${key}XP'] = FieldValue.increment(-value);
      });
      await statsRef.set(updates, SetOptions(merge: true));
      await _updateMuscleXpHistory(
        statsRef: statsRef,
        dayKey: dayKey,
        delta: delta.map((key, value) => MapEntry(key, -value)),
      );
      XpTrace.log('FS_MUSCLE_REMOVE', {
        'traceId': 'remove:$dayKey:$sessionId',
        'primary': primaryMuscleGroupIds.length,
        'secondary': secondaryMuscleGroupIds.length,
        'delta': delta,
      });
    }
  }

  Map<String, int> _buildMuscleXpDelta(
    List<String> primaryMuscleGroupIds,
    List<String> secondaryMuscleGroupIds,
  ) {
    final order = <String>[];
    final weights = <String, int>{};
    final seenPrimary = <String>{};
    final seenSecondary = <String>{};

    void push(String id, int weight, Set<String> seen) {
      if (id.isEmpty) return;
      if (seen.add(id)) {
        order.add(id);
      }
      weights[id] = (weights[id] ?? 0) + weight;
    }

    for (final id in primaryMuscleGroupIds) {
      push(id, 2, seenPrimary);
    }
    for (final id in secondaryMuscleGroupIds) {
      if (seenPrimary.contains(id)) {
        continue;
      }
      push(id, 1, seenSecondary);
    }

    final totalWeight = weights.values.fold<int>(0, (sum, w) => sum + w);
    if (totalWeight == 0) {
      return const {};
    }

    final baseXp = LevelService.xpPerSession;
    final xpPerWeight = baseXp ~/ totalWeight;
    var remainder = baseXp % totalWeight;
    final delta = <String, int>{};
    for (final id in order) {
      final weight = weights[id] ?? 0;
      if (weight == 0) continue;
      var value = weight * xpPerWeight;
      if (remainder > 0) {
        value += 1;
        remainder -= 1;
      }
      delta[id] = value;
    }
    return delta;
  }

  Future<void> _applyMuscleXp({
    required DocumentReference<Map<String, dynamic>> statsRef,
    required List<String> primaryMuscleGroupIds,
    required List<String> secondaryMuscleGroupIds,
    required String traceId,
  }) async {
    final delta = _buildMuscleXpDelta(
      primaryMuscleGroupIds,
      secondaryMuscleGroupIds,
    );
    if (delta.isEmpty) return;
    final updates = <String, dynamic>{};
    delta.forEach((key, value) {
      updates['${key}XP'] = FieldValue.increment(value);
    });
    await statsRef.set(updates, SetOptions(merge: true));
    final dayKey = logicDayKey(DateTime.now().toUtc());
    await _updateMuscleXpHistory(
      statsRef: statsRef,
      dayKey: dayKey,
      delta: delta,
    );
    XpTrace.log('FS_MUSCLE_APPLY', {
      'traceId': traceId,
      'primary': primaryMuscleGroupIds.length,
      'secondary': secondaryMuscleGroupIds.length,
      'delta': delta,
    });
  }

  Future<void> _updateMuscleXpHistory({
    required DocumentReference<Map<String, dynamic>> statsRef,
    required String dayKey,
    required Map<String, int> delta,
  }) async {
    if (delta.isEmpty) return;
    final historyDoc = statsRef.collection('muscleXpHistory').doc(dayKey);
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    delta.forEach((key, value) {
      updates['${key}XP'] = FieldValue.increment(value);
    });
    await historyDoc.set(updates, SetOptions(merge: true));
  }

  Future<T> _runTransactionWithRetry<T>(
    Future<T> Function(Transaction tx) body, {
    required String traceId,
    required String logPrefix,
    int maxRetries = 3,
  }) async {
    var delayMs = 200;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await _firestore.runTransaction<T>(
          (tx) => body(tx),
          maxAttempts: 5,
        );
      } on FirebaseException catch (e) {
        if (e.code != 'resource-exhausted' || attempt == maxRetries) {
          rethrow;
        }
        XpTrace.log('${logPrefix}_TX_RETRY', {
          'traceId': traceId,
          'attempt': attempt + 1,
          'code': e.code,
        });
        await Future<void>.delayed(Duration(milliseconds: delayMs));
        delayMs = delayMs >= 1600 ? 1600 : delayMs * 2;
      }
    }
    throw StateError('Retry loop exited unexpectedly for $traceId');
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

  Stream<Map<String, Map<String, int>>> watchMuscleXpHistory({
    required String gymId,
    required String userId,
  }) {
    final col = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('rank')
        .doc('stats')
        .collection('muscleXpHistory')
        .orderBy(FieldPath.documentId);
    debugPrint('👀 watchMuscleXpHistory userId=$userId gymId=$gymId');
    return col.snapshots().map((snap) {
      final map = <String, Map<String, int>>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final dayMap = <String, int>{};
        data.forEach((key, value) {
          if (key.endsWith('XP') && key != 'dailyXP') {
            final group = key.substring(0, key.length - 2);
            dayMap[group] = (value as num?)?.toInt() ?? 0;
          }
        });
        map[doc.id] = dayMap;
      }
      debugPrint('📥 muscleXpHistory snapshot days=${map.length}');
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
