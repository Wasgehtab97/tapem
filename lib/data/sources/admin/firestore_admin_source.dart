// lib/data/sources/admin/firestore_admin_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreAdminSource {
  final FirebaseFirestore _fs;
  FirestoreAdminSource({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchDevices() =>
      _fs.collection('devices').get().then((snap) => snap.docs);

  Future<String> createDevice({
    required String name,
    required String exerciseMode,
  }) =>
      _fs.collection('devices').add({
        'name': name,
        'exercise_mode': exerciseMode,
        'created_at': FieldValue.serverTimestamp(),
      }).then((doc) => doc.id);

  Future<void> updateDevice({
    required String documentId,
    required String name,
    required String exerciseMode,
    required String secretCode,
  }) =>
      _fs.collection('devices').doc(documentId).update({
        'name': name,
        'exercise_mode': exerciseMode,
        'secret_code': secretCode,
        'updated_at': FieldValue.serverTimestamp(),
      });
}
