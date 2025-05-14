// lib/data/sources/training_details/firestore_training_details_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore‐Source für Details einer Trainingseinheit.
class FirestoreTrainingDetailsSource {
  final FirebaseFirestore _fs;
  final FirebaseAuth _auth;
  FirestoreTrainingDetailsSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _fs = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<String?> getCurrentUserId() async => _auth.currentUser?.uid;

  Future<List<Map<String, dynamic>>> fetchDetailsForDate({
    required String userId,
    required String dateKey,
  }) async {
    final snap = await _fs
        .collection('training_history')
        .where('user_id', isEqualTo: userId)
        .where('training_date', isEqualTo: Timestamp.fromDate(DateTime.parse(dateKey)))
        .get();
    return snap.docs.map((d) => d.data()..['id'] = d.id).toList();
  }
}
