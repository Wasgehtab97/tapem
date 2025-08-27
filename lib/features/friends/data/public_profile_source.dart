import 'package:cloud_firestore/cloud_firestore.dart';
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
    return _firestore
        .collection('publicProfiles')
        .where('usernameLower', isGreaterThanOrEqualTo: prefixLower)
        .where('usernameLower', isLessThan: prefixLower + '\uf8ff')
        .orderBy('usernameLower')
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PublicProfile.fromMap(d.id, d.data())).toList());
  }
}
