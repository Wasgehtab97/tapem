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

      return _firestore.runTransaction<DeviceXpResult>((tx) async {
        final sessSnap = await tx.get(lbSess);
        if (sessSnap.exists) {
          elogDeviceXp('IDEMPOTENT_HIT', {
            'uid': userId,
            'gymId': gymId,
            'deviceId': deviceId,
            'sessionId': sessionId,
            'dayKey': dayKey,
          });
          return DeviceXpResult.idempotentHit;
        }

        final daySnap = await tx.get(lbDay);
        if (daySnap.exists) {
          elogDeviceXp('ALREADY_TODAY', {
            'uid': userId,
            'gymId': gymId,
            'deviceId': deviceId,
            'sessionId': sessionId,
            'dayKey': dayKey,
          });
          return DeviceXpResult.alreadyToday;
        }

        final lbSnap = await tx.get(lbUser);
        var info = LevelInfo.fromMap(lbSnap.data());
        info = LevelService().addXp(info, LevelService.xpPerSession);

        if (!lbSnap.exists) {
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
            if (!(lbSnap.data()?.containsKey('showInLeaderboard') ?? false))
              'showInLeaderboard': showInLeaderboard,
          });
        }

        tx.set(lbDay, {'date': dayKey});
        tx.set(lbSess, {'deviceId': deviceId, 'date': dayKey});

        elogDeviceXp('OK_ADDED', {
          'uid': userId,
          'gymId': gymId,
          'deviceId': deviceId,
          'sessionId': sessionId,
          'dayKey': dayKey,
        });
        return DeviceXpResult.okAdded;
      });
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
