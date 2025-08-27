import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/public_profile.dart';

class PublicProfileSource {
  PublicProfileSource(this._firestore);
  final FirebaseFirestore _firestore;

  Future<PublicProfile> getProfile(String uid) async {
    final doc = await _firestore.collection('publicProfiles').doc(uid).get();
    final data = doc.data();
    if (data == null) {
      throw Exception('not-found');
    }
    return PublicProfile.fromMap(doc.id, data);
  }

  Stream<List<PublicProfile>> searchByUsernamePrefix(String prefixLower,
      {int limit = 20}) {
    final end = prefixLower + '\\uf8ff';
    if (kDebugMode) {
      debugPrint(
          '[FriendSearch] query collection=publicProfiles orderBy=usernameLower startAt=$prefixLower endAt=$end limit=$limit');
    }
    return _firestore
        .collection('publicProfiles')
        .orderBy('usernameLower')
        .startAt([prefixLower])
        .endAt([end])
        .limit(limit)
        .snapshots()
        .map((snap) {
      if (kDebugMode) {
        debugPrint('[FriendSearch] results=${snap.docs.length}');
      }
      return snap.docs
          .map((d) => PublicProfile.fromMap(d.id, d.data()))
          .toList();
    });
  }
}
