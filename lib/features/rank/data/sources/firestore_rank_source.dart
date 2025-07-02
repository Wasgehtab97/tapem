import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../../domain/models/level_info.dart';
import '../../domain/services/level_service.dart';

class FirestoreRankSource {
  final FirebaseFirestore _firestore;

  FirestoreRankSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> addXp({
    required String gymId,
    required String userId,
    required String deviceId,
    required String sessionId,
    required bool showInLeaderboard,
  }) async {
    final now = DateTime.now();
    final dateStr = now.toIso8601String().split('T').first;
    final lbRef = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('leaderboard')
        .doc(userId);
    final sessionRef = lbRef
        .collection('sessions')
        .doc(sessionId);

    await _firestore.runTransaction((tx) async {
      final lbSnap = await tx.get(lbRef);
      var info = LevelInfo.fromMap(lbSnap.data());

      if (!lbSnap.exists) {
        tx.set(lbRef, {
          ...info.toMap(),
          'showInLeaderboard': showInLeaderboard,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final sessSnap = await tx.get(sessionRef);
      if (!sessSnap.exists) {
        info = LevelService().addXp(info, 50);
        tx.set(sessionRef, {
          'deviceId': deviceId,
          'date': dateStr,
        });
        tx.update(lbRef, {
          'xp': info.xp,
          'level': info.level,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
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
        final userSnap =
            await _firestore.collection('users').doc(d.id).get();
        final username = userSnap.data()?['username'] as String?;
        return {'userId': d.id, 'username': username, ...d.data()};
      });
      return Future.wait(futures);
    });
  }
}
