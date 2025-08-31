import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'package:tapem/core/logging/elog.dart';
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

        try {
          final result = await _firestore.runTransaction<DeviceXpResult>((tx) async {
            final userSnap = await tx.get(lbUser);
            final daySnap = await tx.get(lbDay);
            final sessSnap = await tx.get(lbSess);
            elogRank('TXN_READ', {
              'existsUser': userSnap.exists,
              'existsDay': daySnap.exists,
              'existsSess': sessSnap.exists,
              'dayKey': dayKey,
              'userPath': lbUser.path,
              'dayPath': lbDay.path,
              'sessPath': lbSess.path,
            });

            if (sessSnap.exists) {
              elogRank('DECISION_IDEMPOTENT', {
                'sessionId': sessionId,
              });
              return DeviceXpResult.idempotentHit;
            }

            if (daySnap.exists) {
              elogRank('DECISION_ALREADY_TODAY', {
                'sessionId': sessionId,
              });
              return DeviceXpResult.alreadyToday;
            }

            const xpDelta = LevelService.xpPerSession;
            final xpBefore = (userSnap.data()?['xp'] as int?) ?? 0;
            var info = LevelInfo.fromMap(userSnap.data());
            info = LevelService().addXp(info, xpDelta);
            final xpAfter = info.xp;
            elogRank('DECISION_ADD', {
              'xpDelta': xpDelta,
              'xpBefore': xpBefore,
              'xpAfter': xpAfter,
            });

            if (!userSnap.exists) {
              tx.set(lbUser, {
                ...info.toMap(),
                'showInLeaderboard': showInLeaderboard,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            } else {
              tx.update(lbUser, {
                'xp': info.xp,
                'level': info.level,
                'updatedAt': FieldValue.serverTimestamp(),
                if (!(userSnap.data()?.containsKey('showInLeaderboard') ?? false))
                  'showInLeaderboard': showInLeaderboard,
              });
            }

            tx.set(lbDay, {'creditedAt': FieldValue.serverTimestamp()});
            tx.set(lbSess, {
              'sessionId': sessionId,
              'creditedAt': FieldValue.serverTimestamp(),
            });

            return DeviceXpResult.okAdded;
          });

          elogRank('TXN_COMMIT_OK', {
            'userPath': lbUser.path,
            'dayPath': lbDay.path,
            'sessPath': lbSess.path,
          });
          return result;
        } on FirebaseException catch (e, st) {
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
