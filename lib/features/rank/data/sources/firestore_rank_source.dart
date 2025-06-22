// lib/features/rank/data/sources/firestore_rank_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../device_xp.dart';

class FirestoreRankSource {
  final FirebaseFirestore _firestore;

  FirestoreRankSource([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<DeviceXp?> getUserXp({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    final snap = await _firestore
        .collection('gyms').doc(gymId)
        .collection('devices').doc(deviceId)
        .collection('userXp').doc(userId)
        .get();
    if (!snap.exists) return null;
    return DeviceXp.fromDocument(snap);
  }

  Future<void> updateUserXp({
    required String gymId,
    required String deviceId,
    required String userId,
    required int increment,
  }) async {
    final doc = _firestore
        .collection('gyms').doc(gymId)
        .collection('devices').doc(deviceId)
        .collection('userXp').doc(userId);
    await doc.set({
      'xp': FieldValue.increment(increment),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<List<MapEntry<String, DeviceXp>>> getLeaderboard({
    required String gymId,
    required String deviceId,
  }) async {
    final snap = await _firestore
        .collection('gyms').doc(gymId)
        .collection('devices').doc(deviceId)
        .collection('userXp')
        .orderBy('xp', descending: true)
        .get();
    return snap.docs
        .map((d) => MapEntry(d.id, DeviceXp.fromDocument(d)))
        .toList();
  }
}
