import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/features/onboarding_funnel/data/onboarding_funnel_repository.dart';

void main() {
  group('OnboardingFunnelRepository', () {
    late FakeFirebaseFirestore firestore;
    late OnboardingFunnelRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = OnboardingFunnelRepository(firestore: firestore);
    });

    test('getRegisteredMemberCount returns number of members', () async {
      await firestore
          .collection('gyms')
          .doc('gym1')
          .collection('users')
          .doc('user1')
          .set({'memberNumber': '0001'});
      await firestore
          .collection('gyms')
          .doc('gym1')
          .collection('users')
          .doc('user2')
          .set({'memberNumber': '0002'});

      final count = await repository.getRegisteredMemberCount('gym1');

      expect(count, 2);
    });

    test('getMemberByNumber returns summary with training days', () async {
      final createdAt = DateTime(2024, 1, 10);
      final assignedAt = DateTime(2024, 1, 11);
      await firestore
          .collection('gyms')
          .doc('gym1')
          .collection('users')
          .doc('user1')
          .set({
        'memberNumber': '0005',
        'onboardingAssignedAt': Timestamp.fromDate(assignedAt),
      });
      await firestore.collection('users').doc('user1').set({
        'username': 'Alice',
        'email': 'alice@example.com',
        'createdAt': Timestamp.fromDate(createdAt),
      });
      await firestore
          .collection('users')
          .doc('user1')
          .collection('trainingDayXP')
          .doc('2024-01-10')
          .set({'xp': 50});
      await firestore
          .collection('users')
          .doc('user1')
          .collection('trainingDayXP')
          .doc('2024-01-11')
          .set({'xp': 60});

      final result = await repository.getMemberByNumber('gym1', '5');

      expect(result, isNotNull);
      expect(result!.memberNumber, '0005');
      expect(result.displayName, 'Alice');
      expect(result.email, 'alice@example.com');
      expect(result.trainingDays, 2);
      expect(result.registeredAt, createdAt);
      expect(result.onboardingAssignedAt, assignedAt);
    });

    test('getMemberByNumber returns null when not found', () async {
      final result = await repository.getMemberByNumber('gym1', '12');
      expect(result, isNull);
    });
  });
}
