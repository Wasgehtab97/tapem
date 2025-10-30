import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tapem/features/onboarding_funnel/data/sources/firestore_onboarding_source.dart';

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class _MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class _MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class _MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class _MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class _MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class _MockAggregateQuery extends Mock
    implements AggregateQuery<Map<String, dynamic>> {}

void main() {
  group('FirestoreOnboardingSource', () {
    late FirebaseFirestore firestore;
    late CollectionReference<Map<String, dynamic>> gymsCollection;
    late DocumentReference<Map<String, dynamic>> gymDoc;
    late CollectionReference<Map<String, dynamic>> gymUsersCollection;
    late Query<Map<String, dynamic>> membershipQuery;
    late QuerySnapshot<Map<String, dynamic>> membershipQuerySnapshot;
    late QueryDocumentSnapshot<Map<String, dynamic>> membershipDocSnapshot;
    late CollectionReference<Map<String, dynamic>> usersCollection;
    late DocumentReference<Map<String, dynamic>> userDoc;
    late DocumentSnapshot<Map<String, dynamic>> userSnapshot;
    late Query<Map<String, dynamic>> trainingQuery;
    late AggregateQuery<Map<String, dynamic>> aggregateQuery;

    setUp(() {
      firestore = _MockFirebaseFirestore();
      gymsCollection = _MockCollectionReference();
      gymDoc = _MockDocumentReference();
      gymUsersCollection = _MockCollectionReference();
      membershipQuery = _MockQuery();
      membershipQuerySnapshot = _MockQuerySnapshot();
      membershipDocSnapshot = _MockQueryDocumentSnapshot();
      usersCollection = _MockCollectionReference();
      userDoc = _MockDocumentReference();
      userSnapshot = _MockDocumentSnapshot();
      trainingQuery = _MockQuery();
      aggregateQuery = _MockAggregateQuery();

      when(() => firestore.collection('gyms')).thenReturn(gymsCollection);
      when(() => gymsCollection.doc('gym-1')).thenReturn(gymDoc);
      when(() => gymDoc.collection('users')).thenReturn(gymUsersCollection);

      when(() => gymUsersCollection.where(any(), isEqualTo: any(named: 'isEqualTo')))
          .thenReturn(membershipQuery);
      when(() => membershipQuery.limit(1)).thenReturn(membershipQuery);
      when(() => membershipQuery.get())
          .thenAnswer((_) async => membershipQuerySnapshot);
      when(() => membershipQuerySnapshot.docs)
          .thenReturn(<QueryDocumentSnapshot<Map<String, dynamic>>>[
        membershipDocSnapshot,
      ]);
      when(() => membershipDocSnapshot.id).thenReturn('user-1');
      when(() => membershipDocSnapshot.data()).thenReturn(<String, dynamic>{
        'createdAt': Timestamp.fromMillisecondsSinceEpoch(0),
      });

      when(() => firestore.collection('users')).thenReturn(usersCollection);
      when(() => usersCollection.doc('user-1')).thenReturn(userDoc);
      when(() => userDoc.get()).thenAnswer((_) async => userSnapshot);
      when(() => userSnapshot.data()).thenReturn(<String, dynamic>{
        'username': 'tester',
        'email': 'tester@example.com',
        'createdAt': Timestamp.fromMillisecondsSinceEpoch(0),
      });

      when(() => userDoc.collection('trainingDayXP')).thenReturn(trainingQuery);
      when(() => trainingQuery.count()).thenReturn(aggregateQuery);
      when(() => aggregateQuery.get()).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Missing or insufficient permissions.',
        ),
      );
    });

    test('returns 0 training days when permission denied during aggregate query',
        () async {
      final source = FirestoreOnboardingSource(firestore: firestore);

      final detail = await source.fetchMemberDetail('gym-1', '1234');

      expect(detail, isNotNull);
      expect(detail!.totalTrainingDays, 0);
      expect(detail.hasCompletedFirstScan, isFalse);
    });
  });
}
