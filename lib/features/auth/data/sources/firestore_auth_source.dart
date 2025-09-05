import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapem/features/auth/data/dtos/user_data_dto.dart';
import 'package:tapem/features/auth/data/services/username_service.dart';
import 'package:tapem/features/gym/data/sources/firestore_gym_source.dart';

class FirestoreAuthSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirestoreAuthSource({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

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
    final gymSrc = FirestoreGymSource();
    final gym = await gymSrc.getGymByCode(initialGymCode);
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
    await _firestore
        .collection('gyms')
        .doc(gym.id)
        .collection('users')
        .doc(uid)
        .set({
      'role': 'member',
      'createdAt': now,
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
    Future<void> run() => changeUsernameTransaction(
          firestore: _firestore,
          uid: userId,
          newUsername: username,
        );
    try {
      await run();
    } on FirebaseException catch (e) {
      if (e.code == 'aborted') {
        await run();
      } else {
        rethrow;
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
