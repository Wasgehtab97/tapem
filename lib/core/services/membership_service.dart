import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MembershipService {
  final FirebaseFirestore db;
  final FirebaseAuth auth;

  MembershipService(this.db, this.auth);

  Future<void> ensureMembership({required String gymId}) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    final memberRef = db.collection('gyms').doc(gymId).collection('members').doc(uid);
    final snap = await memberRef.get();
    if (snap.exists) return;

    await memberRef.set({
      'role': 'member',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    debugPrint('MEMBERSHIP_CREATE($gymId, $uid)');
  }
}
