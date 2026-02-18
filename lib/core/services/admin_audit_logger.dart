import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuditLogger {
  AdminAuditLogger({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> logGymAction({
    required String gymId,
    required String action,
    required String actorUid,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    if (gymId.isEmpty || action.isEmpty || actorUid.isEmpty) {
      return;
    }
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('adminAudit')
        .add({
          'action': action,
          'actorUid': actorUid,
          'gymId': gymId,
          'metadata': metadata,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}
