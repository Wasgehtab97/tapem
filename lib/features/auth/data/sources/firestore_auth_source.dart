import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapem/features/auth/data/dtos/user_data_dto.dart';

class FirestoreAuthSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirestoreAuthSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserDataDto> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final doc =
        await _firestore.collection('users').doc(uid).get();
    return UserDataDto.fromDocument(doc);
  }

  Future<UserDataDto> register(
      String email, String password, String gymCode) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final now = DateTime.now();
    final dto = UserDataDto(
      email: email,
      gymCode: gymCode,
      role: 'member',
      createdAt: now,
    );
    await _firestore.collection('users').doc(uid).set(dto.toJson());
    dto.userId = uid;
    return dto;
  }

  Future<void> logout() async => _auth.signOut();

  Future<UserDataDto?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc =
        await _firestore.collection('users').doc(user.uid).get();
    return UserDataDto.fromDocument(doc);
  }
}
