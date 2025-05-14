// lib/data/sources/history/firestore_history_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore‐Source für Trainingshistorie.
class FirestoreHistorySource {
  final FirebaseFirestore _fs;
  final FirebaseAuth _auth;
  FirestoreHistorySource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _fs = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<String?> getCurrentUserId() async => _auth.currentUser?.uid;

  Future<List<Map<String, dynamic>>> fetchHistory({
    required String userId,
    required String deviceId,
    String? exercise,
  }) async {
    Query<Map<String, dynamic>> q = _fs
        .collection('training_history')
        .where('user_id', isEqualTo: userId)
        .where('device_id', isEqualTo: deviceId)
        .orderBy('training_date', descending: true);
    if (exercise?.isNotEmpty == true) {
      q = q.where('exercise', isEqualTo: exercise);
    }
    final snap = await q.get();
    return snap.docs.map((d) => d.data()..['id'] = d.id).toList();
  }
}
