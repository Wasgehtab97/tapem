import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/logging/xp_trace.dart';
import 'package:tapem/core/time/logic_day.dart';
import 'package:tapem/features/xp/domain/device_xp_result.dart';

import '../../domain/models/level_info.dart';
import '../../domain/services/level_service.dart';

class FirestoreRankSource {
  final FirebaseFirestore _firestore;

  FirestoreRankSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

      Future<DeviceXpResult> addXp({
        required String gymId,
        required String userId,
        required String deviceId,
        required String sessionId,
        required bool showInLeaderboard,
        required bool isMulti,
        String? exerciseId,
        required String traceId,
      }) async {
        assert(LevelService.xpPerSession == 50);
        assert(deviceId.isNotEmpty);
        final dayKey = logicDayKey(DateTime.now().toUtc());
        final lbUser = _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('devices')
            .doc(deviceId)
            .collection('leaderboard')
            .doc(userId);
        final lbSess = lbUser.collection('sessions').doc(sessionId);
        final lbDay = lbUser.collection('days').doc(dayKey);
        final lbEx = isMulti && exerciseId != null
            ? lbUser.collection('exercises').doc('$exerciseId-$dayKey')
            : null;

        try {
          final result = await _firestore.runTransaction<DeviceXpResult>((tx) async {
            final userSnap = await tx.get(lbUser);
            final daySnap = await tx.get(lbDay);
            final sessSnap = await tx.get(lbSess);
            final exSnap = lbEx != null ? await tx.get(lbEx) : null;
            XpTrace.log('TXN_READ', {
              'existsSessionDoc': sessSnap.exists,
              'existsDayDoc': daySnap.exists,
              'existsExerciseDoc': exSnap?.exists ?? false,
              'xpCurrent': (userSnap.data()?['xp'] as int?) ?? 0,
              'levelCurrent': (userSnap.data()?['level'] as int?) ?? 1,
              'traceId': traceId,
            });

            if (sessSnap.exists) {
              XpTrace.log('TXN_DECISION', {
                'result': 'alreadySession',
                'showInLeaderboard': showInLeaderboard,
                'isMulti': isMulti,
                'exerciseId': exerciseId ?? '',
                'traceId': traceId,
              });
              return DeviceXpResult.idempotentHit;
            }

            if (daySnap.exists || (exSnap?.exists ?? false)) {
              XpTrace.log('TXN_DECISION', {
                'result': daySnap.exists ? 'alreadyToday' : 'alreadyExercise',
                'showInLeaderboard': showInLeaderboard,
                'isMulti': isMulti,
                'exerciseId': exerciseId ?? '',
                'traceId': traceId,
              });
              return daySnap.exists
                  ? DeviceXpResult.alreadyToday
                  : DeviceXpResult.idempotentHit;
            }

            const xpDelta = LevelService.xpPerSession;
            final xpBefore = (userSnap.data()?['xp'] as int?) ?? 0;
            var info = LevelInfo.fromMap(userSnap.data());
            info = LevelService().addXp(info, xpDelta);
            final xpAfter = info.xp;

            if (!userSnap.exists) {
              tx.set(lbUser, {
                ...info.toMap(),
                'userId': userId,
                'showInLeaderboard': showInLeaderboard,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            } else {
              tx.update(lbUser, {
                'xp': info.xp,
                'level': info.level,
                'updatedAt': FieldValue.serverTimestamp(),
                if (!(userSnap.data()?.containsKey('userId') ?? false))
                  'userId': userId,
                if (!(userSnap.data()?.containsKey('showInLeaderboard') ?? false))
                  'showInLeaderboard': showInLeaderboard,
              });
            }

            tx.set(lbDay, {'creditedAt': FieldValue.serverTimestamp()});
            tx.set(lbSess, {
              'sessionId': sessionId,
              'creditedAt': FieldValue.serverTimestamp(),
            });
            bool wroteExercise = false;
            if (lbEx != null) {
              tx.set(lbEx, {'creditedAt': FieldValue.serverTimestamp()});
              wroteExercise = true;
            }

            XpTrace.log('TXN_WRITE', {
              'deltaXp': xpDelta,
              'newXp': xpAfter,
              'newLevel': info.level,
              'wroteSessionMarker': true,
              'wroteDayMarker': true,
              'wroteExerciseMarker': wroteExercise,
              'traceId': traceId,
            });

            return DeviceXpResult.okAdded;
          });

          XpTrace.log('TXN_COMMIT', {
            'result': result.name,
            'traceId': traceId,
          });
          return result;
        } on FirebaseException catch (e, st) {
          XpTrace.log('TXN_ERROR', {
            'code': e.code,
            'path': lbUser.path,
            'traceId': traceId,
          });
          elogError('TXN_FIREBASE_ERROR', e, st, {
            'userPath': lbUser.path,
            'dayKey': dayKey,
          });
          return DeviceXpResult.error;
        }
      }

  Stream<List<Map<String, dynamic>>> watchLeaderboard(
    String gymId,
    String deviceId,
  ) {
    final query = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('leaderboard')
        .where('showInLeaderboard', isEqualTo: true)
        .orderBy('level', descending: true)
        .orderBy('xp', descending: true);

    return query.snapshots().asyncMap((snap) async {
      final futures = snap.docs.map((d) async {
        final userSnap = await _firestore.collection('users').doc(d.id).get();
        final username = userSnap.data()?['username'] as String?;
        return {'userId': d.id, 'username': username, ...d.data()};
      });
      return Future.wait(futures);
    });
  }

  // Removed weekly and monthly leaderboard watchers
}
