import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/public_profile.dart';

class UserSearchSource {
  UserSearchSource(this._firestore);
  final FirebaseFirestore _firestore;

  Future<PublicProfile> getProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) {
      throw Exception('not-found');
    }
    return PublicProfile(
      uid: doc.id,
      username: data['username'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      primaryGymCode:
          (data['gymCodes'] is List && (data['gymCodes'] as List).isNotEmpty)
              ? (data['gymCodes'] as List).first as String
              : null,
      avatarKey: data['avatarKey'] as String? ?? 'default',
    );
  }

  Stream<List<PublicProfile>> streamByUsernamePrefix(String q,
      {int limit = 20}) {
    final prefix = q.trim().toLowerCase();
    final end = '$prefix\uf8ff';
    if (kDebugMode) {
      debugPrint(
          '[FriendSearch] query collection=users orderBy=publicProfile,usernameLower where publicProfile=true startAt=[true,$prefix] endAt=[true,$end] limit=$limit');
    }
    return _firestore
        .collection('users')
        .orderBy('publicProfile')
        .where('publicProfile', isEqualTo: true)
        .orderBy('usernameLower')
        .startAt([true, prefix])
        .endAt([true, end])
        .limit(limit)
        .snapshots()
        .map((snap) {
      if (kDebugMode) {
        debugPrint('[FriendSearch] results=${snap.docs.length}');
      }
      return snap.docs.map((d) {
        final data = d.data();
        return PublicProfile(
          uid: d.id,
          username: data['username'] as String? ?? '',
          avatarUrl: data['avatarUrl'] as String?,
          primaryGymCode:
              (data['gymCodes'] is List && (data['gymCodes'] as List).isNotEmpty)
                  ? (data['gymCodes'] as List).first as String
                  : null,
          avatarKey: data['avatarKey'] as String? ?? 'default',
        );
      }).toList();
    });
  }
}
