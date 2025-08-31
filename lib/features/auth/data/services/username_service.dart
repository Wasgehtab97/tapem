import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> changeUsernameTransaction({
  required FirebaseFirestore firestore,
  required String uid,
  required String newUsername,
}) async {
  final newName = newUsername.trim().replaceAll(RegExp(' +'), ' ');
  final newLower = newName.toLowerCase();
  final userRef = firestore.collection('users').doc(uid);
  final userDoc = await userRef.get();
  if (!userDoc.exists) {
    throw FirebaseException(plugin: 'tapem', code: 'user_not_found');
  }
  final currentLower = userDoc.data()?['usernameLower'] as String?;
  if (currentLower == newLower) {
    return;
  }

  await firestore.runTransaction((tx) async {
    final newRef = firestore.collection('usernames').doc(newLower);
    final newSnap = await tx.get(newRef);
    if (newSnap.exists) {
      final existing = newSnap.data()?['uid'];
      if (existing != uid) {
        throw FirebaseException(plugin: 'tapem', code: 'username_taken');
      } else {
        return; // self-same mapping
      }
    }

    DocumentSnapshot<Map<String, dynamic>>? currentSnap;
    DocumentReference<Map<String, dynamic>>? currentRef;
    if (currentLower != null) {
      currentRef = firestore.collection('usernames').doc(currentLower);
      currentSnap = await tx.get(currentRef);
    }

    tx.set(newRef, {
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (currentSnap != null && currentSnap.exists) {
      tx.delete(currentRef!);
    }
    tx.update(userRef, {
      'username': newName,
      'usernameLower': newLower,
    });
  });
}
