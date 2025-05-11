// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Zentraler Service für Authentifizierung und Gym-ID-Speicherung.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  /// Registriert einen neuen Nutzer (E-Mail/Passwort),
  /// legt in Firestore unter `users/{uid}` das Feld `gymId` an
  /// und speichert User- und Gym-ID lokal.
  Future<UserCredential> register({
    required String email,
    required String password,
    required String displayName,
    required String gymId,
  }) async {
    // 1) Nutzer in Firebase Auth anlegen
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    // 2) Firestore-Dokument mit gymId erstellen
    await _fs.collection('users').doc(uid).set({
      'displayName': displayName,
      'email': email,
      'gymId': gymId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3) Lokal persistieren
    final prefs = await SharedPreferences.getInstance();
    await prefs
      ..setString('userId', uid)
      ..setString('gymId', gymId);

    return cred;
  }

  /// Loggt den Nutzer ein, lädt gymId aus Firestore und speichert lokal.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    // 1) Firebase Auth Login
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    // 2) Firestore-User-Dokument abrufen
    final doc = await _fs.collection('users').doc(uid).get();
    final data = doc.data();
    final gymId = data?['gymId'] as String? ?? '';

    // 3) Lokal persistieren
    final prefs = await SharedPreferences.getInstance();
    await prefs
      ..setString('userId', uid)
      ..setString('gymId', gymId);

    return cred;
  }

  /// Prüft, ob aktuell ein Nutzer angemeldet ist.
  bool get isLoggedIn => _auth.currentUser != null;

  /// Holt die lokal gespeicherte Gym-ID (optional für Auto-Login).
  Future<String?> getSavedGymId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('gymId');
  }

  /// Meldet den Nutzer ab und entfernt lokal gespeicherte Daten.
  Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs
      ..remove('userId')
      ..remove('gymId');
  }
}
