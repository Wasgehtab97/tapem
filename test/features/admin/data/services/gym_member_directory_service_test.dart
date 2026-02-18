import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/observability/owner_action_observability_service.dart';
import 'package:tapem/features/admin/data/services/gym_member_directory_service.dart';

void main() {
  group('GymMemberDirectoryService', () {
    late FakeFirebaseFirestore firestore;
    late OwnerActionObservabilityService observability;
    late GymMemberDirectoryService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      observability = OwnerActionObservabilityService.instance;
      observability.resetForTests();
      service = GymMemberDirectoryService(
        firestore: firestore,
        observability: observability,
      );
    });

    test('watchProfilesForGym emits mapped and sorted profiles', () async {
      await firestore.collection('users').doc('u1').set({
        'username': 'Charlie',
        'usernameLower': 'charlie',
        'gymCodes': <String>['gym-a'],
      });
      await firestore.collection('users').doc('u2').set({
        'username': 'Alice',
        'usernameLower': 'alice',
        'gymCodes': <String>['gym-a'],
      });
      await firestore.collection('users').doc('u3').set({
        'username': 'Bob',
        'usernameLower': 'bob',
        'gymCodes': <String>['gym-b'],
      });

      final profiles = await service.watchProfilesForGym('gym-a').first;
      expect(profiles.length, 2);
      expect(profiles[0].uid, 'u2');
      expect(profiles[1].uid, 'u1');
    });

    test('backfillUsernameLower updates only missing values in gym', () async {
      await firestore.collection('users').doc('u1').set({
        'username': 'Alice',
        'gymCodes': <String>['gym-a'],
      });
      await firestore.collection('users').doc('u2').set({
        'username': 'Bob',
        'usernameLower': 'bob',
        'gymCodes': <String>['gym-a'],
      });
      await firestore.collection('users').doc('u3').set({
        'username': 'Charlie',
        'gymCodes': <String>['gym-b'],
      });

      final updated = await service.backfillUsernameLower(
        'gym-a',
        throttle: Duration.zero,
      );
      expect(updated, 1);

      final u1 = await firestore.collection('users').doc('u1').get();
      final u2 = await firestore.collection('users').doc('u2').get();
      final u3 = await firestore.collection('users').doc('u3').get();
      expect(u1.data()!['usernameLower'], 'alice');
      expect(u2.data()!['usernameLower'], 'bob');
      expect(u3.data()!['usernameLower'], isNull);

      final metric = observability.metrics.metricFor(
        'owner.symbols.backfill_username_lower',
      );
      expect(metric.attempts, 1);
      expect(metric.successes, 1);
      expect(metric.failures, 0);
    });

    test('watchDisplayName returns username and falls back to uid', () async {
      await firestore.collection('users').doc('u1').set({'username': 'Alice'});
      await firestore.collection('users').doc('u2').set({'username': ''});

      final name1 = await service.watchDisplayName('u1', fallback: 'u1').first;
      final name2 = await service.watchDisplayName('u2', fallback: 'u2').first;
      final name3 = await service.watchDisplayName('u3', fallback: 'u3').first;

      expect(name1, 'Alice');
      expect(name2, 'u2');
      expect(name3, 'u3');
    });
  });
}
