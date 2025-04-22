// lib/services/api_services.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Zentrale API-Services für die Gym-App.
class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Zugriff auf FirebaseAuth
  FirebaseAuth get auth => _auth;

  /// Aktuell eingeloggter User
  User? get currentUser => _auth.currentUser;

  /// Aktuelle Benutzer‑ID (Firebase UID)
  String? get currentUserId => _auth.currentUser?.uid;

  // ─── Geräte ────────────────────────────────────────────────────────────────

  /// Liefert alle Geräte und mappt das numeric‑Feld `id` auf `deviceId`,
  /// behält die Firestore‑Dokument‑ID unter `documentId`.
  Future<List<Map<String, dynamic>>> getDevices() async {
    final snap = await _firestore.collection('devices').get();
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      // Firestore-Feld "id" ist hier die numerische Geräte-ID
      data['deviceId'] = data['id'];
      // Speichere die Firestore-Dokument-ID als documentId
      data['documentId'] = doc.id;
      return data;
    }).toList();
  }

  /// Erstellt ein neues Gerät und gibt dessen Dokument-ID zurück.
  Future<String> createDevice(String name, String exerciseMode) async {
    final doc = await _firestore.collection('devices').add({
      'name': name,
      'exercise_mode': exerciseMode,
      'secret_code': DateTime.now().millisecondsSinceEpoch.toString(),
      'created_at': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Ruft ein Gerät per Dokument‑ID und Secret-Code ab.
  Future<Map<String, dynamic>?> getDeviceBySecret(
      String documentId, String secretCode) async {
    final doc = await _firestore.collection('devices').doc(documentId).get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    if (data['secret_code'] == secretCode) {
      data['deviceId'] = data['id'];
      data['documentId'] = doc.id;
      return data;
    }
    return null;
  }

  /// Aktualisiert ein Gerät (über Dokument‑ID) und liefert die aktualisierten Daten.
  Future<Map<String, dynamic>> updateDevice(
    String documentId,
    String name,
    String exerciseMode,
    String secretCode,
  ) async {
    await _firestore.collection('devices').doc(documentId).update({
      'name': name,
      'exercise_mode': exerciseMode,
      'secret_code': secretCode,
      'updated_at': FieldValue.serverTimestamp(),
    });
    final updated = await _firestore.collection('devices').doc(documentId).get();
    final data = Map<String, dynamic>.from(updated.data()!);
    data['deviceId'] = data['id'];
    data['documentId'] = updated.id;
    return data;
  }

  // ─── Trainingshistorie (Top‑Level‑Collection) ─────────────────────────────────

  /// Speichert eine Trainingseinheit in der Collection `training_history`.
  Future<void> postTrainingSession(
      String userId, Map<String, dynamic> sessionData) async {
    await _firestore.collection('training_history').add({
      'user_id': userId,
      ...sessionData,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Holt Trainingseinheiten mit optionalen Filtern.
  Future<List<Map<String, dynamic>>> getTrainingSessions({
    required String userId,
    String? deviceId,
    String? exercise,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('training_history')
        .orderBy('training_date', descending: true)
        .where('user_id', isEqualTo: userId);

    if (startDate != null) {
      query = query.where(
          'training_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where(
          'training_date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    if (exercise != null && exercise.isNotEmpty) {
      query = query.where('exercise', isEqualTo: exercise);
    } else if (deviceId != null && deviceId.isNotEmpty) {
      query = query.where('device_id', isEqualTo: deviceId);
    }

    try {
      final snap = await query.get();
      return snap.docs.map((doc) {
        final m = Map<String, dynamic>.from(doc.data());
        m['id'] = doc.id;
        return m;
      }).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        // Fallback: Client-seitiges Filtern & Sortieren
        final snap = await _firestore
            .collection('training_history')
            .where('user_id', isEqualTo: userId)
            .get();
        var all = snap.docs.map((doc) {
          final m = Map<String, dynamic>.from(doc.data());
          m['id'] = doc.id;
          return m;
        }).toList();
        if (deviceId != null && deviceId.isNotEmpty) {
          all = all.where((m) => m['device_id'] == deviceId).toList();
        }
        if (exercise != null && exercise.isNotEmpty) {
          all = all.where((m) => m['exercise'] == exercise).toList();
        }
        all.sort((a, b) {
          final ta = a['training_date'] as Timestamp;
          final tb = b['training_date'] as Timestamp;
          return tb.compareTo(ta);
        });
        return all;
      }
      rethrow;
    }
  }

  // ─── Auth & Benutzer ───────────────────────────────────────────────────────

  Future<UserCredential> registerUser(
    String email,
    String password,
    String name,
    String membershipNumber,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user?.updateDisplayName(name);
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'email': email,
      'membership_number': membershipNumber,
      'current_streak': 0,
      'role': 'user',
      'exp': 0,
      'exp_progress': 0,
      'division_number': 0,
      'created_at': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  Future<UserCredential> loginUser(String email, String password) async =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<Map<String, dynamic>> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) throw Exception('User data not found');
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return data;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snap = await _firestore.collection('users').get();
    return snap.docs.map((d) {
      final m = Map<String, dynamic>.from(d.data());
      m['id'] = d.id;
      return m;
    }).toList();
  }

  // ─── Trainingspläne ────────────────────────────────────────────────────────

  Future<String> createTrainingPlan(String userId, String name) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingPlans')
        .add({
      'name': name,
      'status': 'inaktiv',
      'created_at': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<List<Map<String, dynamic>>> getTrainingPlans(String userId) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingPlans')
        .get();
    return snap.docs.map((d) {
      final m = Map<String, dynamic>.from(d.data());
      m['id'] = d.id;
      return m;
    }).toList();
  }

  Future<void> updateTrainingPlan(
    String userId,
    String planId,
    List<Map<String, dynamic>> exercises,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingPlans')
        .doc(planId)
        .update({
      'exercises': exercises,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTrainingPlan(String userId, String planId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingPlans')
        .doc(planId)
        .delete();
  }

  Future<void> startTrainingPlan(String userId, String planId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingPlans')
        .doc(planId)
        .update({
      'status': 'aktiv',
      'started_at': FieldValue.serverTimestamp(),
    });
  }

  // ─── Coach‑Features ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getClientsForCoach(String coachId) async {
    final snap = await _firestore
        .collection('users')
        .where('coach_id', isEqualTo: coachId)
        .get();
    return snap.docs.map((d) {
      final m = Map<String, dynamic>.from(d.data());
      m['id'] = d.id;
      return m;
    }).toList();
  }

  Future<void> sendCoachingRequest(String coachId, String clientId) async {
    await _firestore.collection('coaching_requests').add({
      'coach_id': coachId,
      'client_id': clientId,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendCoachingRequestByMembership(
      String membershipNumber) async {
    final snap = await _firestore
        .collection('users')
        .where('membership_number', isEqualTo: membershipNumber)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      throw Exception(
          'Kein Benutzer mit dieser Mitgliedsnummer gefunden.');
    }
    final clientId = snap.docs.first.id;
    final coachId = currentUserId!;
    await sendCoachingRequest(coachId, clientId);
  }

  Future<void> respondCoachingRequest(
      String requestId, bool accept) async {
    await _firestore.collection('coaching_requests').doc(requestId).update({
      'status': accept ? 'accepted' : 'rejected',
      'responded_at': FieldValue.serverTimestamp(),
    });
  }

  // ─── Affiliate-Angebote ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAffiliateOffers() async {
    final snap = await _firestore.collection('affiliateOffers').get();
    return snap.docs.map((d) {
      final m = Map<String, dynamic>.from(d.data());
      m['id'] = d.id;
      return m;
    }).toList();
  }

  Future<void> trackAffiliateClick(String offerId) async {
    await _firestore.collection('affiliateClicks').add({
      'offerId': offerId,
      'clicked_at': FieldValue.serverTimestamp(),
    });
  }

  // ─── Custom Exercises ───────────────────────────────────────────────────────

  Future<String> createCustomExercise(
      String userId, String deviceId, String name) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('customExercises')
        .add({
      'device_id': deviceId,
      'name': name,
      'created_at': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<List<Map<String, dynamic>>> getCustomExercises(
      String userId, String deviceId) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('customExercises')
        .where('device_id', isEqualTo: deviceId)
        .get();
    return snap.docs.map((d) {
      final m = Map<String, dynamic>.from(d.data());
      m['id'] = d.id;
      return m;
    }).toList();
  }

  Future<void> deleteCustomExercise(
      String userId, String deviceId, String name) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('customExercises')
        .where('device_id', isEqualTo: deviceId)
        .where('name', isEqualTo: name)
        .get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}
