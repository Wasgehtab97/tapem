import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/features/onboarding_funnel/data/repositories/onboarding_funnel_repository.dart';
import 'package:tapem/features/onboarding_funnel/data/sources/firestore_onboarding_source.dart';
import 'package:tapem/features/onboarding_funnel/domain/models/gym_member_detail.dart';

void main() {
  group('OnboardingFunnelRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreOnboardingSource source;
    late OnboardingFunnelRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      source = FirestoreOnboardingSource(firestore: firestore);
      repository = OnboardingFunnelRepository(source: source);
    });

    test('returns member count', () async {
      await firestore.collection('gyms').doc('gymA').collection('users').doc('user1').set({
        'role': 'member',
        'memberNumber': '0001',
      });
      await firestore.collection('gyms').doc('gymA').collection('users').doc('user2').set({
        'role': 'member',
        'memberNumber': '0002',
      });

      final count = await repository.getMemberCount('gymA');

      expect(count, 2);
    });

    test('finds member details with training stats', () async {
      await firestore.collection('gyms').doc('gymA').collection('users').doc('user1').set({
        'role': 'member',
        'memberNumber': '0015',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 10)),
      });
      await firestore.collection('users').doc('user1').set({
        'email': 'member@example.com',
        'username': 'member',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 5)),
      });
      await firestore
          .collection('users')
          .doc('user1')
          .collection('trainingDayXP')
          .doc('2024-01-01')
          .set({'xp': 10});
      await firestore
          .collection('users')
          .doc('user1')
          .collection('trainingDayXP')
          .doc('2024-01-02')
          .set({'xp': 12});

      final detail = await repository.findMemberByNumber('gymA', '15');

      expect(detail, isA<GymMemberDetail>());
      expect(detail!.summary.userId, 'user1');
      expect(detail.memberNumber, '0015');
      expect(detail.summary.createdAt, DateTime(2024, 1, 10));
      expect(detail.totalTrainingDays, 2);
      expect(detail.hasCompletedFirstScan, isTrue);
      expect(detail.displayName, 'member');
    });

    test('supports numeric memberNumber fields', () async {
      await firestore.collection('gyms').doc('gymA').collection('users').doc('user1').set({
        'role': 'member',
        'memberNumber': 9,
      });

      final detail = await repository.findMemberByNumber('gymA', '0009');

      expect(detail, isA<GymMemberDetail>());
      expect(detail!.memberNumber, '0009');
    });

    test('returns null when member not found', () async {
      final detail = await repository.findMemberByNumber('gymA', '0001');
      expect(detail, isNull);
    });

    test('wraps FirebaseException in repository exception for count', () async {
      final throwingRepository = OnboardingFunnelRepository(
        source: _ThrowingSource(
          onCount: () => throw FirebaseException(code: 'internal', plugin: 'cloud_firestore'),
        ),
      );

      expect(
        () => throwingRepository.getMemberCount('gymA'),
        throwsA(isA<OnboardingFunnelException>()),
      );
    });

    test('wraps FirebaseException in repository exception for detail', () async {
      final throwingRepository = OnboardingFunnelRepository(
        source: _ThrowingSource(
          onDetail: () => throw FirebaseException(code: 'internal', plugin: 'cloud_firestore'),
        ),
      );

      expect(
        () => throwingRepository.findMemberByNumber('gymA', '0001'),
        throwsA(isA<OnboardingFunnelException>()),
      );
    });
  });
}

class _ThrowingSource extends FirestoreOnboardingSource {
  _ThrowingSource({this.onCount, this.onDetail}) : super(firestore: FakeFirebaseFirestore());

  final Future<int> Function()? onCount;
  final Future<GymMemberDetail?> Function()? onDetail;

  @override
  Future<int> countMembers(String gymId) {
    if (onCount != null) {
      return onCount!();
    }
    return super.countMembers(gymId);
  }

  @override
  Future<GymMemberDetail?> fetchMemberDetail(String gymId, String memberNumber) {
    if (onDetail != null) {
      return onDetail!();
    }
    return super.fetchMemberDetail(gymId, memberNumber);
  }
}
