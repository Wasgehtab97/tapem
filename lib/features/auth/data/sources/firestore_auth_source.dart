import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapem/features/auth/data/dtos/user_data_dto.dart';
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
      role: 'member',
      createdAt: now,
    );
    await _firestore.collection('users').doc(uid).set(dto.toJson());

    // Nutzer zusätzlich unterhalb des Gyms referenzieren
    await _firestore
        .collection('gyms')
        .doc(gym.id)
        .collection('users')
        .doc(uid)
        .set({
      'role': 'member',
      'createdAt': Timestamp.fromDate(now),
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
    final query = await _firestore
        .collection('users')
        .where('usernameLower', isEqualTo: lower)
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  Future<void> setUsername(String userId, String username) async {
    final lower = username.toLowerCase();
    await _firestore.collection('users').doc(userId).update({
      'username': username,
      'usernameLower': lower,
    });
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }
}
