import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/logging/xp_trace.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/rank/data/sources/firestore_rank_source.dart';
import 'package:tapem/features/rank/domain/models/level_info.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:tapem/features/xp/domain/muscle_xp_calculator.dart';
import 'package:tapem/features/xp/domain/device_xp_result.dart';

class FirestoreXpSource {
  final FirebaseFirestore _firestore;
  final FirestoreRankSource _rankSource;

  FirestoreXpSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _rankSource = FirestoreRankSource(firestore: firestore);

  static const int _historyLimit = 30;
  static const int _trainingDayLimit = 30;

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
              XpTrace.log('FS_READ', {
                'path': dayRef.path,
                'context': 'addSessionXp.day',
                'traceId': traceId,
              });
              final daySnap = await tx.get(dayRef);
              XpTrace.log('FS_READ_RESULT', {
                'path': dayRef.path,
                'exists': daySnap.exists,
                'traceId': traceId,
              });
              XpTrace.log('FS_READ', {
                'path': statsRef.path,
                'context': 'addSessionXp.stats',
                'traceId': traceId,
              });
              final statsSnap = await tx.get(statsRef);
              XpTrace.log('FS_READ_RESULT', {
                'path': statsRef.path,
                'exists': statsSnap.exists,
                'traceId': traceId,
              });
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
      XpTrace.log('FS_READ', {
        'path': dayRef.path,
        'context': 'removeSessionXp.day',
      });
      final daySnap = await tx.get(dayRef);
      XpTrace.log('FS_READ', {
        'path': statsRef.path,
        'context': 'removeSessionXp.stats',
      });
      final statsSnap = await tx.get(statsRef);
      XpTrace.log('FS_READ', {
        'path': lbUser.path,
        'context': 'removeSessionXp.lbUser',
      });
      final lbUserSnap = await tx.get(lbUser);
      XpTrace.log('FS_READ', {
        'path': lbSess.path,
        'context': 'removeSessionXp.lbSess',
      });
      final lbSessSnap = await tx.get(lbSess);
      XpTrace.log('FS_READ', {
        'path': lbDay.path,
        'context': 'removeSessionXp.lbDay',
      });
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

    final delta = MuscleXpCalculator.calculateDelta(
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

  Future<void> _applyMuscleXp({
    required DocumentReference<Map<String, dynamic>> statsRef,
    required List<String> primaryMuscleGroupIds,
    required List<String> secondaryMuscleGroupIds,
    required String traceId,
  }) async {
    final delta = MuscleXpCalculator.calculateDelta(
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

  Future<int> fetchDayXp({required String userId, required DateTime date}) async {
    final dateStr = logicDayKey(date.toUtc());
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingDayXP')
        .doc(dateStr);
    debugPrint('⬇️ fetchDayXp userId=$userId date=$dateStr');
    final snap = await ref.get();
    final xp = (snap.data()?['xp'] as int?) ?? 0;
    debugPrint('✅ fetchDayXp -> $xp');
    return xp;
  }

  Future<Map<String, int>> fetchMuscleXp({
    required String gymId,
    required String userId,
  }) async {
    final doc = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('rank')
        .doc('stats');
    debugPrint('⬇️ fetchMuscleXp userId=$userId gymId=$gymId');
    final snap = await doc.get();
    final data = snap.data() ?? <String, dynamic>{};
    final map = <String, int>{};
    for (final entry in data.entries) {
      final key = entry.key;
      if (key.endsWith('XP') && key != 'dailyXP') {
        final group = key.substring(0, key.length - 2);
        map[group] = (entry.value as num?)?.toInt() ?? 0;
      }
    }
    debugPrint('✅ fetchMuscleXp entries=${map.length}');
    return map;
  }

  Future<Map<String, Map<String, int>>> fetchMuscleXpHistory({
    required String gymId,
    required String userId,
    int limit = _historyLimit,
  }) async {
    final col = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('rank')
        .doc('stats')
        .collection('muscleXpHistory')
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit);
    debugPrint(
        '⬇️ fetchMuscleXpHistory userId=$userId gymId=$gymId limit=$limit');
    final snap = await col.get();
    final docs = snap.docs.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final map = <String, Map<String, int>>{};
    for (final docSnap in docs) {
      final data = docSnap.data();
      final dayMap = <String, int>{};
      data.forEach((key, value) {
        if (key.endsWith('XP') && key != 'dailyXP') {
          final group = key.substring(0, key.length - 2);
          dayMap[group] = (value as num?)?.toInt() ?? 0;
        }
      });
      map[docSnap.id] = dayMap;
    }
    debugPrint('✅ fetchMuscleXpHistory days=${map.length}');
    return map;
  }

  Future<Map<String, int>> fetchTrainingDaysXp(
    String userId, {
    int limit = _trainingDayLimit,
  }) async {
    final col = _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingDayXP')
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit);
    debugPrint('⬇️ fetchTrainingDaysXp userId=$userId limit=$limit');
    final snap = await col.get();
    final docs = snap.docs.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final map = <String, int>{};
    for (final docSnap in docs) {
      map[docSnap.id] = (docSnap.data()['xp'] as num?)?.toInt() ?? 0;
    }
    debugPrint('✅ fetchTrainingDaysXp days=${map.length}');
    return map;
  }

  Future<int> fetchDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    final doc = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('leaderboard')
        .doc(userId);
    debugPrint(
      '⬇️ fetchDeviceXp gymId=$gymId deviceId=$deviceId userId=$userId',
    );
    final snap = await doc.get();
    final xp = (snap.data()?['xp'] as num?)?.toInt() ?? 0;
    debugPrint('✅ fetchDeviceXp -> $xp');
    return xp;
  }

  Future<int> fetchStatsDailyXp({
    required String gymId,
    required String userId,
  }) async {
    final doc = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(userId)
        .collection('rank')
        .doc('stats');
    debugPrint('⬇️ fetchStatsDailyXp gymId=$gymId userId=$userId');
    final snap = await doc.get();
    final xp = (snap.data()?['dailyXP'] as num?)?.toInt() ?? 0;
    debugPrint('✅ fetchStatsDailyXp -> $xp');
    return xp;
  }
}
