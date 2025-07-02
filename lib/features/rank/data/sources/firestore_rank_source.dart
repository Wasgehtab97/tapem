import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreRankSource {
  final FirebaseFirestore _firestore;

  FirestoreRankSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> addXp({
    required String gymId,
    required String userId,
    required String deviceId,
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
        .collection('dailySessions')
        .doc(dateStr);

    await _firestore.runTransaction((tx) async {
      final lbSnap = await tx.get(lbRef);
      if (!lbSnap.exists) {
        tx.set(lbRef, {
          'xp': 0,
          'showInLeaderboard': showInLeaderboard,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      final sessSnap = await tx.get(sessionRef);
      if (!sessSnap.exists) {
        tx.set(sessionRef, {'deviceId': deviceId, 'date': dateStr});
        tx.update(lbRef, {
          'xp': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Stream<List<Map<String, dynamic>>> watchLeaderboard(
    String gymId,
    String deviceId,
  ) {
    return _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('leaderboard')
        .where('showInLeaderboard', isEqualTo: true)
        .orderBy('xp', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => {'userId': d.id, ...d.data()}).toList(),
        );
  }
}
