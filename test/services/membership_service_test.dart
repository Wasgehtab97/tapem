import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/services/membership_service.dart';

void main() {
  group('FirestoreMembershipService', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreMembershipService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = FirestoreMembershipService(firestore: firestore);
    });

    Future<DocumentSnapshot<Map<String, dynamic>>> membershipSnap(
      String gymId,
      String uid,
    ) {
      return firestore
          .collection('gyms')
          .doc(gymId)
          .collection('users')
          .doc(uid)
          .get();
    }

    test('allocates sequential member numbers with timestamps', () async {
      await firestore
          .collection('gyms')
          .doc('G1')
          .collection('users')
          .doc('userA')
          .set({'role': 'member'});

      await service.ensureMembership('G1', 'userA');
      final first = await membershipSnap('G1', 'userA');
      final firstData = first.data();

      expect(firstData?['memberNumber'], '0001');
      expect(firstData?['role'], 'member');
      expect(firstData?['createdAt'], isA<Timestamp>());

      await firestore
          .collection('gyms')
          .doc('G1')
          .collection('users')
          .doc('userB')
          .set({'role': 'member'});

      await service.ensureMembership('G1', 'userB');
      final second = await membershipSnap('G1', 'userB');
      final secondData = second.data();

      expect(secondData?['memberNumber'], '0002');
      expect(secondData?['createdAt'], isA<Timestamp>());

      final onboarding = await firestore
          .collection('gyms')
          .doc('G1')
          .collection('config')
          .doc('onboarding')
          .get();
      expect(onboarding.data()?['nextMemberNumber'], 3);
    });

    test('throws when member number pool is exhausted', () async {
      await firestore
          .collection('gyms')
          .doc('G1')
          .collection('config')
          .doc('onboarding')
          .set({'nextMemberNumber': 10000});
      await firestore
          .collection('gyms')
          .doc('G1')
          .collection('users')
          .doc('userA')
          .set({'role': 'member'});

      await expectLater(
        () => service.ensureMembership('G1', 'userA'),
        throwsA(isA<StateError>()),
      );

      final onboarding = await firestore
          .collection('gyms')
          .doc('G1')
          .collection('config')
          .doc('onboarding')
          .get();
      expect(onboarding.data()?['nextMemberNumber'], 10000);

      final membership = await membershipSnap('G1', 'userA');
      expect(membership.data()?['memberNumber'], isNull);
    });

    test('does not change existing member number', () async {
      await firestore
          .collection('gyms')
          .doc('G1')
          .collection('config')
          .doc('onboarding')
          .set({'nextMemberNumber': 8});
      await firestore
          .collection('gyms')
          .doc('G1')
          .collection('users')
          .doc('userA')
          .set({
        'role': 'member',
        'memberNumber': '0042',
        'createdAt': Timestamp.now(),
      });

      await service.ensureMembership('G1', 'userA');

      final membership = await membershipSnap('G1', 'userA');
      expect(membership.data()?['memberNumber'], '0042');

      final onboarding = await firestore
          .collection('gyms')
          .doc('G1')
          .collection('config')
          .doc('onboarding')
          .get();
      expect(onboarding.data()?['nextMemberNumber'], 8);
    });
  });
}
