// lib/data/sources/auth/firestore_auth_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firestore‐Source für Authentifizierung.
class FirestoreAuthSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _fs;
  FirestoreAuthSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _fs = firestore ?? FirebaseFirestore.instance;

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String gymId,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    await _fs.collection('users').doc(uid).set({
      'displayName': displayName,
      'email': email,
      'gymId': gymId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final prefs = await SharedPreferences.getInstance();
    prefs
      ..setString('userId', uid)
      ..setString('gymId', gymId);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final doc = await _fs.collection('users').doc(uid).get();
    final gymId = doc.data()?['gymId'] as String? ?? '';
    final prefs = await SharedPreferences.getInstance();
    prefs
      ..setString('userId', uid)
      ..setString('gymId', gymId);
  }

  Future<String?> getSavedGymId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('gymId');
  }

  Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    prefs
      ..remove('userId')
      ..remove('gymId');
  }
}
