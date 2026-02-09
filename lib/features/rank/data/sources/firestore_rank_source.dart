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
    final dayKey = logicDayKey(DateTime.now());
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
      final result = await _runTransactionWithRetry<DeviceXpResult>((tx) async {
        final userSnap = await tx.get(lbUser);
        final sessSnap = await tx.get(lbSess);
        XpTrace.log('TXN_READ', {
          'existsSessionDoc': sessSnap.exists,
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

        const xpDelta = LevelService.xpPerSession;
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
            'showInLeaderboard': showInLeaderboard,
            'updatedAt': FieldValue.serverTimestamp(),
            if (!(userSnap.data()?.containsKey('userId') ?? false))
              'userId': userId,
          });
        }

        tx.set(lbDay, {
          'creditedAt': FieldValue.serverTimestamp(),
          'sessionCount': FieldValue.increment(1),
        }, SetOptions(merge: true));
        tx.set(lbSess, {
          'sessionId': sessionId,
          'creditedAt': FieldValue.serverTimestamp(),
        });

        XpTrace.log('TXN_WRITE', {
          'deltaXp': xpDelta,
          'newXp': xpAfter,
          'newLevel': info.level,
          'wroteSessionMarker': true,
          'wroteDayMarker': true,
          'traceId': traceId,
        });

        return DeviceXpResult.okAdded;
      }, traceId: traceId);

      XpTrace.log('TXN_COMMIT', {'result': result.name, 'traceId': traceId});
      return result;
    } on FirebaseException catch (e, st) {
      XpTrace.log('TXN_ERROR', {
        'code': e.code,
        'path': lbUser.path,
        'traceId': traceId,
      });
      if (e.code == 'permission-denied') {
        elogRank('SECURITY_DENIED', {
          'action': 'leaderboard write',
          'gymId': gymId,
          'deviceId': deviceId,
          'uid': userId,
          'reason': 'rules-path',
        });
        return DeviceXpResult.okAddedNoLeaderboard;
      }
      elogError('TXN_FIREBASE_ERROR', e, st, {
        'userPath': lbUser.path,
        'dayKey': dayKey,
      });
      return DeviceXpResult.error;
    }
  }

  Future<T> _runTransactionWithRetry<T>(
    Future<T> Function(Transaction tx) body, {
    required String traceId,
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
        XpTrace.log('TXN_RETRY', {
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
