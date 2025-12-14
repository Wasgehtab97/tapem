import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

/// Firestore-basierte Audit-Logs für Coaching-Aktionen.
///
/// Ziel: einfache Nachvollziehbarkeit, wer welche Coaching-relevante
/// Aktion ausgelöst hat (z.B. Anfrage, Statuswechsel, Planänderung).
class FirestoreCoachingAuditSource {
  FirestoreCoachingAuditSource([FirebaseFirestore? instance])
      : _firestore = instance ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> logEvent({
    required String gymId,
    required String type,
    String? coachId,
    String? clientId,
    String? relationId,
    String? planId,
    String? inviteId,
  }) async {
    final actor = fb_auth.FirebaseAuth.instance.currentUser;
    final actorId = actor?.uid;
    if (actorId == null || actorId.isEmpty) {
      // Ohne Actor-Info macht das Log wenig Sinn – in diesem Fall überspringen.
      return;
    }

    final now = DateTime.now();

    try {
      await _firestore.collection('coachingEvents').add({
        'gymId': gymId,
        'type': type,
        'actorId': actorId,
        if (coachId != null) 'coachId': coachId,
        if (clientId != null) 'clientId': clientId,
        if (relationId != null) 'relationId': relationId,
        if (planId != null) 'planId': planId,
        if (inviteId != null) 'inviteId': inviteId,
        'createdAt': now.toIso8601String(),
      });
    } catch (_) {
      // Audit-Logging ist "best effort" – Fehler hier sollen keine
      // User-Flows blockieren.
    }
  }
}

