import 'package:cloud_firestore/cloud_firestore.dart';

class SessionMetaSource {
  final FirebaseFirestore _firestore;
  SessionMetaSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getMeta({
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
}
