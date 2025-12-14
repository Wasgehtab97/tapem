import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tapem/features/coaching/domain/models/coach_invite.dart';
import 'package:tapem/features/coaching/data/sources/firestore_coaching_audit_source.dart';

class FirestoreCoachInviteSource {
  final FirebaseFirestore _firestore;
  final FirestoreCoachingAuditSource _audit;

  FirestoreCoachInviteSource([FirebaseFirestore? instance])
      : _firestore = instance ?? FirebaseFirestore.instance,
        _audit = FirestoreCoachingAuditSource(instance);

  CollectionReference<Map<String, dynamic>> get _invites =>
      _firestore.collection('coachInvites');

  Future<void> createInvite({
    required String gymId,
    required String clientId,
    required String email,
  }) async {
    final now = DateTime.now();
    final doc = await _invites.add({
      'gymId': gymId,
      'clientId': clientId,
      'email': email,
      'status': 'pending',
      'createdAt': now.toIso8601String(),
    });

    await _audit.logEvent(
      gymId: gymId,
      type: 'external_coach_invite_created',
      clientId: clientId,
      inviteId: doc.id,
    );
  }

  Future<List<CoachInvite>> getInvitesForClient({
    required String clientId,
  }) async {
    final snapshot =
        await _invites.where('clientId', isEqualTo: clientId).get();
    return snapshot.docs
        .map((doc) => CoachInvite.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  Future<List<CoachInvite>> getPendingInvitesForEmail({
    required String email,
  }) async {
    final snapshot = await _invites
        .where('email', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs
        .map((doc) => CoachInvite.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  Future<void> markInviteAccepted({
    required String inviteId,
    required String coachId,
  }) async {
    final now = DateTime.now();
    final doc = _invites.doc(inviteId);
    final snapshot = await doc.get();
    final data = snapshot.data();
    final gymId = (data?['gymId'] as String?) ?? '';

    await doc.set({
      'status': 'accepted',
      'acceptedAt': now.toIso8601String(),
      'coachId': coachId,
    }, SetOptions(merge: true));

    if (gymId.isNotEmpty) {
      await _audit.logEvent(
        gymId: gymId,
        type: 'external_coach_invite_accepted',
        clientId: data?['clientId'] as String?,
        coachId: coachId,
        inviteId: inviteId,
      );
    }
  }
}
