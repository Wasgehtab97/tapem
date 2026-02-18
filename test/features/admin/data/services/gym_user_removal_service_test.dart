import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/observability/owner_action_observability_service.dart';
import 'package:tapem/core/services/admin_audit_logger.dart';
import 'package:tapem/features/admin/data/services/gym_user_removal_service.dart';

void main() {
  group('GymUserRemovalService', () {
    late FakeFirebaseFirestore firestore;
    late GymUserRemovalService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      OwnerActionObservabilityService.instance.resetForTests();
      service = GymUserRemovalService(
        firestore: firestore,
        auditLogger: AdminAuditLogger(firestore: firestore),
        observability: OwnerActionObservabilityService.instance,
      );
    });

    test(
      'detaches membership, cleans scoped data, and writes admin audit',
      () async {
        await firestore.collection('users').doc('user-1').set({
          'gymCodes': ['gym-a', 'gym-b'],
          'activeGymId': 'gym-a',
        });
        await firestore
            .collection('gyms')
            .doc('gym-a')
            .collection('users')
            .doc('user-1')
            .set({'role': 'member'});
        await firestore
            .collection('gyms')
            .doc('gym-a')
            .collection('users')
            .doc('user-1')
            .collection('rank')
            .doc('day-1')
            .set({'xp': 42});
        await firestore
            .collection('gyms')
            .doc('gym-a')
            .collection('users')
            .doc('user-1')
            .collection('completedChallenges')
            .doc('c-1')
            .set({'done': true});

        final deviceRef = firestore
            .collection('gyms')
            .doc('gym-a')
            .collection('devices')
            .doc('device-1');
        await deviceRef.set({'name': 'Device'});
        await deviceRef.collection('logs').doc('l-1').set({'userId': 'user-1'});
        await deviceRef.collection('logs').doc('l-2').set({'userId': 'user-2'});
        await deviceRef.collection('sessions').doc('s-1').set({
          'userId': 'user-1',
        });
        await deviceRef.collection('leaderboard').doc('user-1').set({
          'userId': 'user-1',
        });
        await deviceRef
            .collection('leaderboard')
            .doc('user-1')
            .collection('days')
            .doc('20260216')
            .set({'done': true});
        await deviceRef
            .collection('leaderboard')
            .doc('user-1')
            .collection('sessions')
            .doc('sess-1')
            .set({'done': true});
        await deviceRef
            .collection('leaderboard')
            .doc('user-1')
            .collection('exercises')
            .doc('ex-1')
            .set({'done': true});
        await deviceRef.collection('userNotes').doc('user-1').set({
          'note': 'x',
        });

        final machineRef = firestore
            .collection('gyms')
            .doc('gym-a')
            .collection('machines')
            .doc('machine-1');
        await machineRef.set({'name': 'Machine'});
        await machineRef.collection('attempts').doc('a-1').set({
          'userId': 'user-1',
        });
        await machineRef.collection('attempts').doc('a-2').set({
          'userId': 'user-2',
        });

        final result = await service.removeUserFromGym(
          gymId: 'gym-a',
          targetUid: 'user-1',
          actorUid: 'owner-1',
        );

        expect(result.hasCleanupWarnings, isFalse);
        expect(result.cleanupErrors, isEmpty);

        final userDoc = await firestore.collection('users').doc('user-1').get();
        expect(userDoc.exists, isTrue);
        expect(userDoc.data()!['gymCodes'], ['gym-b']);
        expect(userDoc.data()!['activeGymId'], 'gym-b');

        final membership = await firestore
            .collection('gyms')
            .doc('gym-a')
            .collection('users')
            .doc('user-1')
            .get();
        expect(membership.exists, isFalse);

        final userLogDeleted = await deviceRef
            .collection('logs')
            .doc('l-1')
            .get();
        final foreignLogKept = await deviceRef
            .collection('logs')
            .doc('l-2')
            .get();
        expect(userLogDeleted.exists, isFalse);
        expect(foreignLogKept.exists, isTrue);

        final userSessionDeleted = await deviceRef
            .collection('sessions')
            .doc('s-1')
            .get();
        expect(userSessionDeleted.exists, isFalse);

        final leaderboardDeleted = await deviceRef
            .collection('leaderboard')
            .doc('user-1')
            .get();
        expect(leaderboardDeleted.exists, isFalse);
        final userNoteDeleted = await deviceRef
            .collection('userNotes')
            .doc('user-1')
            .get();
        expect(userNoteDeleted.exists, isFalse);

        final machineAttemptDeleted = await machineRef
            .collection('attempts')
            .doc('a-1')
            .get();
        final machineAttemptKept = await machineRef
            .collection('attempts')
            .doc('a-2')
            .get();
        expect(machineAttemptDeleted.exists, isFalse);
        expect(machineAttemptKept.exists, isTrue);

        final audit = await firestore
            .collection('gyms')
            .doc('gym-a')
            .collection('adminAudit')
            .get();
        expect(audit.docs.length, 1);
        final auditData = audit.docs.first.data();
        expect(auditData['action'], 'remove_user_from_gym_client');
        expect(auditData['actorUid'], 'owner-1');
        expect(auditData['gymId'], 'gym-a');
        expect(auditData['metadata'], containsPair('targetUid', 'user-1'));
        expect(auditData['metadata'], containsPair('cleanupWarnings', 0));

        final metric = OwnerActionObservabilityService.instance.metrics
            .metricFor('owner.remove_user_from_gym');
        expect(metric.attempts, 1);
        expect(metric.successes, 1);
        expect(metric.failures, 0);
        expect(metric.permissionDenied, 0);
      },
    );

    test('removing last gym clears activeGymId', () async {
      await firestore.collection('users').doc('user-2').set({
        'gymCodes': ['gym-a'],
        'activeGymId': 'gym-a',
      });
      await firestore
          .collection('gyms')
          .doc('gym-a')
          .collection('users')
          .doc('user-2')
          .set({'role': 'member'});

      await service.removeUserFromGym(
        gymId: 'gym-a',
        targetUid: 'user-2',
        actorUid: 'owner-1',
      );

      final userDoc = await firestore.collection('users').doc('user-2').get();
      expect(userDoc.exists, isTrue);
      expect(userDoc.data()!['gymCodes'], isEmpty);
      expect(userDoc.data()!.containsKey('activeGymId'), isFalse);
    });

    test('throws not-found when target user does not exist', () async {
      await expectLater(
        () => service.removeUserFromGym(
          gymId: 'gym-a',
          targetUid: 'missing-user',
          actorUid: 'owner-1',
        ),
        throwsA(
          isA<FirebaseException>().having(
            (error) => error.code,
            'code',
            'not-found',
          ),
        ),
      );

      final metric = OwnerActionObservabilityService.instance.metrics.metricFor(
        'owner.remove_user_from_gym',
      );
      expect(metric.attempts, 1);
      expect(metric.successes, 0);
      expect(metric.failures, 1);
      expect(metric.permissionDenied, 0);
      expect(metric.lastErrorCode, 'not-found');
    });
  });
}
