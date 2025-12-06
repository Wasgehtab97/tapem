import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/friends/domain/models/public_profile.dart';

class UserProfileService {
  static Future<void> setActiveGym(String gymId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'activeGymId': gymId}, SetOptions(merge: true));
  }

  Future<PublicProfile?> getPublicProfile(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    if (!doc.exists) return null;
    return PublicProfile.fromFirestore(doc);
  }
}
