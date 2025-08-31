import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/rank/data/sources/firestore_rank_source.dart';
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
    }) async {
      final dayKey = logicDayKey(DateTime.now());
      elogDeviceXp('ATTEMPT', {
        'uid': userId,
        'gymId': gymId,
        'deviceId': deviceId,
        'sessionId': sessionId,
        'isMulti': isMulti,
        'dayKey': dayKey,
        'source': 'xp_source',
      });
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

      await _firestore.runTransaction((tx) async {
        debugPrint('⏳ transaction start');
        // All reads must happen before any writes in a transaction.
        final daySnap = await tx.get(dayRef);
        final statsSnap = await tx.get(statsRef);
        final statsData = statsSnap.data() ?? {};
        final updates = <String, dynamic>{};

        final currentDayXp = (daySnap.data()?['xp'] as int?) ?? 0;
        final newDayXp = currentDayXp + LevelService.xpPerSession;
        debugPrint('👉 dayXP $currentDayXp -> $newDayXp');
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
        debugPrint('⏳ transaction updates: $updates');
      });
      debugPrint('✅ stored session XP');

      final result = await _rankSource.addXp(
        gymId: gymId,
        userId: userId,
        deviceId: deviceId,
        sessionId: sessionId,
        showInLeaderboard: showInLeaderboard,
      );
      return result;
    }

  Stream<int> watchDayXp({required String userId, required DateTime date}) {
    final dateStr = date.toIso8601String().split('T').first;
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
