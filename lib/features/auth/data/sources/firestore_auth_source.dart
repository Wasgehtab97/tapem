import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapem/features/auth/data/dtos/user_data_dto.dart';
import 'package:tapem/features/auth/data/services/username_service.dart';
import 'package:tapem/features/gym/domain/services/gym_code_service.dart';
import 'package:tapem/services/member_number_utils.dart';

typedef ChangeUsernameRunner = Future<void> Function({
  required FirebaseFirestore firestore,
  required String uid,
  required String newUsername,
});

class FirestoreAuthSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final ChangeUsernameRunner _changeUsername;
  final GymCodeService _gymCodeService;

  FirestoreAuthSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    ChangeUsernameRunner? changeUsername,
    GymCodeService? gymCodeService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _changeUsername = changeUsername ?? changeUsernameTransaction,
        _gymCodeService = gymCodeService ??
            GymCodeService(firestore: firestore ?? FirebaseFirestore.instance);

  Future<UserDataDto> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User document not found.');
    return UserDataDto.fromDocument(doc);
  }

  Future<UserDataDto> register(
    String email,
    String password,
    String initialGymCode,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    // Validate gym code using new rotating code system
    // This will throw GymCodeExpiredException, GymCodeNotFoundException, etc.
    final validation = await _gymCodeService.validateCode(initialGymCode);
    final gymId = validation.gymId;

    final now = DateTime.now();
    final dto = UserDataDto(
      userId: uid,
      email: email,
      emailLower: email.toLowerCase(),
      userName: null,
      userNameLower: null,
      gymCodes: [gymId],  // Store gym ID, not the code!
      showInLeaderboard: true,
      publicProfile: false,
      role: 'member',
      createdAt: now,
    );
    await _firestore.collection('users').doc(uid).set(dto.toJson());

    await _firestore.runTransaction((tx) async {
      final gymRef = _firestore.collection('gyms').doc(gymId);
      final membershipRef = gymRef.collection('users').doc(uid);

      final gymSnap = await tx.get(gymRef);
      final nextNumber = nextMemberNumber(gymSnap.data(), gymId: gymId);
      final memberNumber = formatMemberNumber(nextNumber);

      updateMemberNumberCounter(tx, gymRef, nextNumber);
      tx.set(
        membershipRef,
        {
          'role': 'member',
          'createdAt': now,
          'memberNumber': memberNumber,
        },
        SetOptions(merge: true),
      );
    });

    return dto;
  }

  Future<void> logout() async => _auth.signOut();

  Future<UserDataDto?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserDataDto.fromDocument(doc);
  }

  Future<bool> isUsernameAvailable(String username) async {
    final lower = username.toLowerCase();
    final doc = await _firestore.collection('usernames').doc(lower).get();
    return !doc.exists;
  }

  Future<void> setUsername(String userId, String username) async {
    const retryable = {'aborted', 'resource-exhausted', 'unavailable'};
    var attempts = 0;
    while (true) {
      try {
        await _changeUsername(
          firestore: _firestore,
          uid: userId,
          newUsername: username,
        );
        return;
      } on FirebaseException catch (e) {
        if (!retryable.contains(e.code) || attempts >= 2) {
          rethrow;
        }
        attempts += 1;
        await Future<void>.delayed(Duration(milliseconds: 100 * attempts));
      }
    }
  }

  Future<void> setShowInLeaderboard(String userId, bool value) async {
    await _firestore.collection('users').doc(userId).update({
      'showInLeaderboard': value,
    });
  }

  Future<void> setPublicProfile(String userId, bool value) async {
    await _firestore.collection('users').doc(userId).update({
      'publicProfile': value,
    });
  }

  Future<void> setCoachEnabled(String userId, bool value) async {
    await _firestore.collection('users').doc(userId).update({
      'coachEnabled': value,
    });
  }

  Future<void> setAvatarKey(String userId, String avatarKey) async {
    await _firestore.collection('users').doc(userId).update({
      'avatarKey': avatarKey,
      'avatarUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setPublicKey(String userId, String publicKey) async {
    await _firestore.collection('users').doc(userId).update({
      'publicKey': publicKey,
    });
  }

  Future<void> sendPasswordResetEmail(String email) {
    // Use default Firebase password reset email
    // This avoids "Domain not allowlisted" errors
    return _auth.sendPasswordResetEmail(email: email);
  }
}
