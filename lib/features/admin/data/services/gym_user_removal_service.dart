import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/core/observability/owner_action_observability_service.dart';
import 'package:tapem/core/services/admin_audit_logger.dart';

class GymUserRemovalResult {
  const GymUserRemovalResult({required this.cleanupErrors});

  final List<String> cleanupErrors;

  bool get hasCleanupWarnings => cleanupErrors.isNotEmpty;
}

class GymUserRemovalService {
  GymUserRemovalService({
    FirebaseFirestore? firestore,
    AdminAuditLogger? auditLogger,
    OwnerActionObservabilityService? observability,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditLogger = auditLogger ?? AdminAuditLogger(),
       _observability =
           observability ?? OwnerActionObservabilityService.instance;

  final FirebaseFirestore _firestore;
  final AdminAuditLogger _auditLogger;
  final OwnerActionObservabilityService _observability;

  Future<GymUserRemovalResult> removeUserFromGym({
    required String gymId,
    required String targetUid,
    required String actorUid,
  }) async {
    return _observability.trackAction(
      action: 'owner.remove_user_from_gym',
      command: () async {
        await _detachMembership(gymId: gymId, targetUid: targetUid);

        final cleanupErrors = <String>[];
        await _cleanupBestEffort(
          gymId: gymId,
          targetUid: targetUid,
          onError: cleanupErrors.add,
        );

        await _auditLogger.logGymAction(
          gymId: gymId,
          action: 'remove_user_from_gym_client',
          actorUid: actorUid,
          metadata: <String, dynamic>{
            'targetUid': targetUid,
            'cleanupWarnings': cleanupErrors.length,
          },
        );

        return GymUserRemovalResult(cleanupErrors: cleanupErrors);
      },
    );
  }

  Future<void> _detachMembership({
    required String gymId,
    required String targetUid,
  }) async {
    final userRef = _firestore.collection('users').doc(targetUid);
    final membershipRef = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .doc(targetUid);

    await _firestore.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'User $targetUid not found.',
        );
      }

      final userData = userSnap.data() ?? const <String, dynamic>{};
      final gymCodes = ((userData['gymCodes'] as List?) ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false);
      final nextGymCodes = gymCodes
          .where((code) => code != gymId)
          .toList(growable: false);

      final updates = <String, dynamic>{
        'gymCodes': nextGymCodes,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if ((userData['activeGymId'] as String?) == gymId) {
        if (nextGymCodes.length == 1) {
          updates['activeGymId'] = nextGymCodes.first;
        } else {
          updates['activeGymId'] = FieldValue.delete();
        }
      }

      tx.set(userRef, updates, SetOptions(merge: true));
      tx.delete(membershipRef);
    });
  }

  Future<void> _cleanupBestEffort({
    required String gymId,
    required String targetUid,
    required void Function(String error) onError,
  }) async {
    final gymRef = _firestore.collection('gyms').doc(gymId);
    final gymUserRef = gymRef.collection('users').doc(targetUid);

    Future<void> guard(String label, Future<void> Function() action) async {
      try {
        await action();
      } catch (error) {
        onError('$label: $error');
      }
    }

    for (final name in const [
      'rank',
      'completedChallenges',
      'rest_stats',
      'rest_stats_applied',
    ]) {
      await guard(
        'users/$targetUid/$name',
        () => _deleteCollection(gymUserRef.collection(name)),
      );
    }

    final devicesSnap = await gymRef.collection('devices').get();
    for (final deviceDoc in devicesSnap.docs) {
      await guard(
        'devices/${deviceDoc.id}/logs',
        () => _deleteQuery(
          deviceDoc.reference
              .collection('logs')
              .where('userId', isEqualTo: targetUid),
        ),
      );
      await guard(
        'devices/${deviceDoc.id}/sessions',
        () => _deleteQuery(
          deviceDoc.reference
              .collection('sessions')
              .where('userId', isEqualTo: targetUid),
        ),
      );
      await guard(
        'devices/${deviceDoc.id}/leaderboard/$targetUid',
        () => _deleteLeaderboardEntry(
          leaderboardRef: deviceDoc.reference
              .collection('leaderboard')
              .doc(targetUid),
        ),
      );
      await guard(
        'devices/${deviceDoc.id}/userNotes/$targetUid',
        () async =>
            deviceDoc.reference.collection('userNotes').doc(targetUid).delete(),
      );
    }

    final machinesSnap = await gymRef.collection('machines').get();
    for (final machineDoc in machinesSnap.docs) {
      await guard(
        'machines/${machineDoc.id}/attempts',
        () => _deleteQuery(
          machineDoc.reference
              .collection('attempts')
              .where('userId', isEqualTo: targetUid),
        ),
      );
    }
  }

  Future<void> _deleteLeaderboardEntry({
    required DocumentReference<Map<String, dynamic>> leaderboardRef,
  }) async {
    for (final sub in const ['days', 'sessions', 'exercises']) {
      await _deleteCollection(leaderboardRef.collection(sub));
    }
    await leaderboardRef.delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collectionRef, {
    int pageSize = 200,
  }) async {
    while (true) {
      final snap = await collectionRef.limit(pageSize).get();
      if (snap.docs.isEmpty) {
        return;
      }
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snap.docs.length < pageSize) {
        return;
      }
    }
  }

  Future<void> _deleteQuery(
    Query<Map<String, dynamic>> query, {
    int pageSize = 200,
  }) async {
    while (true) {
      final snap = await query.limit(pageSize).get();
      if (snap.docs.isEmpty) {
        return;
      }
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snap.docs.length < pageSize) {
        return;
      }
    }
  }
}
