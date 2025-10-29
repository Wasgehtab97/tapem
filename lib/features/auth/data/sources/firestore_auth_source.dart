import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapem/features/auth/data/dtos/user_data_dto.dart';
import 'package:tapem/features/auth/data/services/username_service.dart';
import 'package:tapem/features/gym/data/sources/firestore_gym_source.dart';
import 'package:tapem/services/membership_service.dart';

typedef ChangeUsernameRunner = Future<void> Function({
  required FirebaseFirestore firestore,
  required String uid,
  required String newUsername,
});

class FirestoreAuthSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final ChangeUsernameRunner _changeUsername;
  final FirestoreGymSource _gymSource;
  final MembershipService _membership;

  FirestoreAuthSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    ChangeUsernameRunner? changeUsername,
    FirestoreGymSource? gymSource,
    MembershipService? membership,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _changeUsername = changeUsername ?? changeUsernameTransaction,
        _gymSource = gymSource ?? FirestoreGymSource(),
        _membership =
            membership ?? FirestoreMembershipService(firestore: firestore);

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

    // Gym anhand des Codes suchen und dessen ID speichern
    final gym = await _gymSource.getGymByCode(initialGymCode);
    if (gym == null) throw Exception('Gym code not found');

    final now = DateTime.now();
    final dto = UserDataDto(
      userId: uid,
      email: email,
      emailLower: email.toLowerCase(),
      userName: null,
      userNameLower: null,
      gymCodes: [gym.id],
      showInLeaderboard: true,
      publicProfile: false,
      role: 'member',
      createdAt: now,
    );
    await _firestore.collection('users').doc(uid).set(dto.toJson());

    // create gym membership so the user can access gym data
    await _membership.ensureMembership(
      gym.id,
      uid,
      createdAt: now,
    );

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

  Future<void> setAvatarKey(String userId, String avatarKey) async {
    await _firestore.collection('users').doc(userId).update({
      'avatarKey': avatarKey,
      'avatarUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendPasswordResetEmail(String email) {
    final settings = ActionCodeSettings(
      url: 'https://tapem.page.link/reset',
      handleCodeInApp: true,
      androidPackageName: 'com.example.tapem',
      iOSBundleId: 'com.example.tapem',
      androidInstallApp: true,
      dynamicLinkDomain: 'tapem.page.link',
    );
    return _auth.sendPasswordResetEmail(
      email: email,
      actionCodeSettings: settings,
    );
  }
}
