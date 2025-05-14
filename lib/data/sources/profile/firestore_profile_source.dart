// lib/data/sources/profile/firestore_profile_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore‐Source für Nutzer‐Profile.
class FirestoreProfileSource {
  final FirebaseFirestore _fs;
  final FirebaseAuth _auth;
  FirestoreProfileSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _fs = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<String?> getCurrentUserId() async => _auth.currentUser?.uid;

  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    final doc = await _fs.collection('users').doc(userId).get();
    return doc.data() ?? {};
  }

  Future<List<String>> fetchTrainingDates(String userId) async {
    final snap = await _fs
        .collection('training_history')
        .where('user_id', isEqualTo: userId)
        .get();
    return snap.docs
        .map((d) => (d.data()['training_date'] as Timestamp)
            .toDate()
            .toIso8601String()
            .split('T')
            .first)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>?> fetchPendingCoachingRequest(
      String userId) async {
    final snap = await _fs
        .collection('coaching_requests')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return {'id': snap.docs.first.id, ...snap.docs.first.data()};
  }

  Future<void> respondToCoachingRequest(
      String requestId, bool accept) {
    return _fs.collection('coaching_requests').doc(requestId).update({
      'status': accept ? 'accepted' : 'rejected',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() async {
    // optional: Firestore‐Cleanup
  }
}
