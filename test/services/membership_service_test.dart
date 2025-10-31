import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/services/membership_service.dart';

void main() {
  group('FirestoreMembershipService', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreMembershipService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = FirestoreMembershipService(
        firestore: firestore,
        log: (_, [__]) {},
      );
    });

    test('ensureMembership creates membership with sequential member number', () async {
      await firestore.collection('gyms').doc('gym-1').set({'name': 'Test Gym'});

      await service.ensureMembership('gym-1', 'user-1');

      final membership = await firestore
          .collection('gyms')
          .doc('gym-1')
          .collection('users')
          .doc('user-1')
          .get();
      final gym = await firestore.collection('gyms').doc('gym-1').get();

      expect(membership.exists, isTrue);
      expect(membership.data(), containsPair('memberNumber', '0001'));
      expect(gym.data(), containsPair('memberNumberCounter', 1));
    });

    test('ensureMembership keeps existing member number', () async {
      await firestore.collection('gyms').doc('gym-1').set({'memberNumberCounter': 10});
      await firestore
          .collection('gyms')
          .doc('gym-1')
          .collection('users')
          .doc('user-1')
          .set({'memberNumber': '0010', 'role': 'member'});

      await service.ensureMembership('gym-1', 'user-1');

      final membership = await firestore
          .collection('gyms')
          .doc('gym-1')
          .collection('users')
          .doc('user-1')
          .get();
      final gym = await firestore.collection('gyms').doc('gym-1').get();

      expect(membership.data(), containsPair('memberNumber', '0010'));
      expect(gym.data(), containsPair('memberNumberCounter', 10));
    });

    test('ensureMembership assigns member number when missing on existing membership', () async {
      await firestore.collection('gyms').doc('gym-1').set({'memberNumberCounter': 3});
      await firestore
          .collection('gyms')
          .doc('gym-1')
          .collection('users')
          .doc('user-1')
          .set({'role': 'member'});

      await service.ensureMembership('gym-1', 'user-1');

      final membership = await firestore
          .collection('gyms')
          .doc('gym-1')
          .collection('users')
          .doc('user-1')
          .get();
      final gym = await firestore.collection('gyms').doc('gym-1').get();

      expect(membership.data(), containsPair('memberNumber', '0004'));
      expect(gym.data(), containsPair('memberNumberCounter', 4));
    });
  });
}
