import 'package:cloud_firestore/cloud_firestore.dart';

class SessionMetaSource {
  final FirebaseFirestore _firestore;
  SessionMetaSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> upsertMeta({
    required String gymId,
    required String uid,
    required String sessionId,
    required Map<String, dynamic> meta,
  }) async {
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(uid)
        .collection('session_meta')
        .doc(sessionId)
        .set(meta, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getMetaBySessionId({
    required String gymId,
    required String uid,
    required String sessionId,
  }) async {
    final doc = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(uid)
        .collection('session_meta')
        .doc(sessionId)
        .get();
    return doc.data();
  }

  Future<Map<String, dynamic>?> getMetaByDayKey({
    required String gymId,
    required String uid,
    required String dayKey,
  }) async {
    final snap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(uid)
        .collection('session_meta')
        .where('dayKey', isEqualTo: dayKey)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }
}
