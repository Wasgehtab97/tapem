import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:tapem/core/providers/functions_provider.dart';
import 'package:tapem/features/auth/data/dtos/user_data_dto.dart';
import 'package:tapem/features/gym/data/sources/firestore_gym_source.dart';

class FirestoreAuthSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirestoreAuthSource({FirebaseAuth? auth, FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      _functions = functions ?? FunctionsProvider.instance;

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
    try {
      await _functions
          .httpsCallable('changeUsername')
          .call({'newUsername': username});
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found' || e.code == 'unavailable') {
        await _fallbackSetUsername(userId, username);
      } else if (e.code == 'already-exists' || e.message == 'username_taken') {
        throw Exception('Username already taken');
      } else if (e.code == 'invalid-argument') {
        throw Exception('Invalid username');
      } else {
        rethrow;
      }
    }
  }

  Future<void> _fallbackSetUsername(String userId, String username) async {
    final target = username.trim();
    final regex = RegExp(r'^[A-Za-z0-9 ]{3,20}$');
    if (!regex.hasMatch(target)) {
      throw Exception('Invalid username');
    }
    final lower = target.toLowerCase();
    final userRef = _firestore.collection('users').doc(userId);
    await _firestore.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) {
        throw Exception('User not found');
      }
      final oldLower = userSnap.data()?['usernameLower'];
      if (oldLower == lower) return;
      final mappingRef = _firestore.collection('usernames').doc(lower);
      final mappingSnap = await tx.get(mappingRef);
      if (mappingSnap.exists && mappingSnap.data()?['uid'] != userId) {
        throw Exception('Username already taken');
      }
      if (oldLower != null) {
        tx.delete(_firestore.collection('usernames').doc(oldLower));
      }
      tx.set(mappingRef, {
        'uid': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(userRef, {
        'username': target,
        'usernameLower': lower,
      });
    });
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
