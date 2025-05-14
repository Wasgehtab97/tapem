// lib/data/sources/coach/firestore_coach_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreCoachSource {
  final FirebaseFirestore _fs;
  FirestoreCoachSource({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> loadClients(
          String coachId) =>
      _fs
          .collection('users')
          .doc(coachId)
          .collection('clients')
          .get()
          .then((snap) => snap.docs);

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchTrainingDates(
          String clientId) async =>
      (await _fs
              .collection('training_history')
              .where('user_id', isEqualTo: clientId)
              .get())
          .docs;

  Future<void> sendCoachingRequest(
          String coachId, String membershipNumber) =>
      _fs.collection('coaching_requests').add({
        'membership_number': membershipNumber,
        'coach_id': coachId,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });
}
