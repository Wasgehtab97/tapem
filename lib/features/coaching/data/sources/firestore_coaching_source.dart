import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tapem/core/logging/app_logger.dart';
import 'package:tapem/features/coaching/domain/models/coach_client_relation.dart';
import 'package:tapem/features/coaching/data/sources/firestore_coaching_audit_source.dart';

class FirestoreCoachingSource {
  final FirebaseFirestore _firestore;
  final FirestoreCoachingAuditSource _audit;

  FirestoreCoachingSource([
    FirebaseFirestore? instance,
    FirestoreCoachingAuditSource? audit,
  ])  : _firestore = instance ?? FirebaseFirestore.instance,
        _audit = audit ?? FirestoreCoachingAuditSource(instance);

  CollectionReference<Map<String, dynamic>> get _relations =>
      _firestore.collection('coachClientRelations');

  Future<bool> _hasActiveCoach({
    required String gymId,
    required String clientId,
  }) async {
    final snapshot = await _relations
        .where('gymId', isEqualTo: gymId)
        .where('clientId', isEqualTo: clientId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<List<CoachClientRelation>> getRelationsForCoach({
    required String coachId,
  }) async {
    AppLogger.d(
      'getRelationsForCoach coachId=$coachId',
      tag: 'CoachingSource',
    );
    try {
      final snapshot = await _relations
          .where('coachId', isEqualTo: coachId)
          .get();
      AppLogger.d(
        'getRelationsForCoach coachId=$coachId docs=${snapshot.docs.length}',
        tag: 'CoachingSource',
      );
      return snapshot.docs
          .map(
            (doc) =>
                CoachClientRelation.fromJson(doc.data(), id: doc.id),
          )
          .toList();
    } on FirebaseException catch (e) {
      AppLogger.w(
        'getRelationsForCoach firestore error code=${e.code} message=${e.message}',
        tag: 'CoachingSource',
        error: e,
      );
      rethrow;
    } catch (e) {
      AppLogger.w(
        'getRelationsForCoach error',
        tag: 'CoachingSource',
        error: e,
      );
      rethrow;
    }
  }

  Future<List<CoachClientRelation>> getRelationsForClient({
    required String clientId,
  }) async {
    AppLogger.d(
      'getRelationsForClient clientId=$clientId',
      tag: 'CoachingSource',
    );
    try {
      final snapshot = await _relations
          .where('clientId', isEqualTo: clientId)
          .get();
      AppLogger.d(
        'getRelationsForClient clientId=$clientId docs=${snapshot.docs.length}',
        tag: 'CoachingSource',
      );
      return snapshot.docs
          .map(
            (doc) =>
                CoachClientRelation.fromJson(doc.data(), id: doc.id),
          )
          .toList();
    } on FirebaseException catch (e) {
      AppLogger.w(
        'getRelationsForClient firestore error code=${e.code} message=${e.message}',
        tag: 'CoachingSource',
        error: e,
      );
      rethrow;
    } catch (e) {
      AppLogger.w(
        'getRelationsForClient error',
        tag: 'CoachingSource',
        error: e,
      );
      rethrow;
    }
  }

  Future<void> requestCoaching({
    required String gymId,
    required String coachId,
    required String clientId,
  }) async {
    final now = DateTime.now();
    final relationId = '${gymId}_${coachId}_$clientId';
    AppLogger.i(
      'requestCoaching gymId=$gymId coachId=$coachId '
      'clientId=$clientId relationId=$relationId',
      tag: 'CoachingSource',
    );
    // Maximal genau eine aktive Coach-Beziehung pro Client/Gym.
    // Mehrere pending-Anfragen sind erlaubt; hier prüfen wir nur,
    // ob bereits eine aktive Beziehung existiert, um spätere
    // Konsistenzprobleme zu vermeiden.
    final hasActive = await _hasActiveCoach(gymId: gymId, clientId: clientId);
    if (hasActive) {
      // Wir legen trotzdem eine pending-Relation an, der spätere
      // Statuswechsel auf „active“ wird beim Aktivieren konsistent
      // auf genau einen aktiven Coach begrenzt.
    }

    await _relations.doc(relationId).set(
      {
        'gymId': gymId,
        'coachId': coachId,
        'clientId': clientId,
        'status': 'pending',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      SetOptions(merge: true),
    );

    await _audit.logEvent(
      gymId: gymId,
      type: 'relation_requested',
      coachId: coachId,
      clientId: clientId,
      relationId: relationId,
    );
  }

  Future<void> updateRelationStatus({
    required String relationId,
    required String status,
    String? endedReason,
  }) async {
    final now = DateTime.now();
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': now.toIso8601String(),
    };
    if (status == 'ended') {
      updates['endedAt'] = now.toIso8601String();
      if (endedReason != null) {
        updates['endedReason'] = endedReason;
      }
    }
    AppLogger.i(
      'updateRelationStatus relationId=$relationId status=$status '
      'endedReason=$endedReason',
      tag: 'CoachingSource',
    );
    await _relations.doc(relationId).set(updates, SetOptions(merge: true));

    final docRef = _relations.doc(relationId);
    final doc = await docRef.get();
    final data = doc.data();
    final gymId = data?['gymId'] as String? ?? '';
    final coachId = data?['coachId'] as String?;
    final clientId = data?['clientId'] as String?;

    // Wenn eine Relation auf „active“ gesetzt wird, sorgen wir dafür,
    // dass es pro (gymId, clientId) nur genau einen aktiven Coach gibt.
    if (status == 'active' && gymId.isNotEmpty && clientId != null) {
      final others = await _relations
          .where('gymId', isEqualTo: gymId)
          .where('clientId', isEqualTo: clientId)
          .where('status', isEqualTo: 'active')
          .get();
      for (final other in others.docs) {
        if (other.id == relationId) continue;
        await other.reference.set(
          {
            'status': 'ended',
            'updatedAt': now.toIso8601String(),
            'endedAt': now.toIso8601String(),
            'endedReason': 'superseded_by_other_coach',
          },
          SetOptions(merge: true),
        );
      }
    }

    if (gymId.isNotEmpty) {
      await _audit.logEvent(
        gymId: gymId,
        type: 'relation_status_changed',
        coachId: coachId,
        clientId: clientId,
        relationId: relationId,
      );
    }
  }
}
