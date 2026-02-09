import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/data/services/username_service.dart';

import '../../helpers/fake_firestore.dart';

void main() {
  group('changeUsernameTransaction', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('throws username_invalid for malformed username', () async {
      await firestore.seedDocument('users/u1', {
        'username': 'Old',
        'usernameLower': 'old',
      });

      expect(
        () => changeUsernameTransaction(
          firestore: firestore,
          uid: 'u1',
          newUsername: 'x!',
        ),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'username_invalid',
          ),
        ),
      );
    });

    test(
      'updates users + usernames mapping and removes previous mapping',
      () async {
        await firestore.seedDocument('users/u1', {
          'username': 'Old Name',
          'usernameLower': 'old name',
        });
        await firestore.seedDocument('usernames/old name', {
          'uid': 'u1',
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        });

        await changeUsernameTransaction(
          firestore: firestore,
          uid: 'u1',
          newUsername: 'New Name',
        );

        final user = await firestore.collection('users').doc('u1').get();
        final oldMap = await firestore
            .collection('usernames')
            .doc('old name')
            .get();
        final newMap = await firestore
            .collection('usernames')
            .doc('new name')
            .get();

        expect(user.data(), containsPair('username', 'New Name'));
        expect(user.data(), containsPair('usernameLower', 'new name'));
        expect(oldMap.exists, isFalse);
        expect(newMap.exists, isTrue);
        expect(newMap.data(), containsPair('uid', 'u1'));
      },
    );

    test('throws username_taken when mapped to another uid', () async {
      await firestore.seedDocument('users/u1', {
        'username': 'Old',
        'usernameLower': 'old',
      });
      await firestore.seedDocument('usernames/taken', {
        'uid': 'u2',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });

      expect(
        () => changeUsernameTransaction(
          firestore: firestore,
          uid: 'u1',
          newUsername: 'Taken',
        ),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'username_taken',
          ),
        ),
      );
    });
  });
}
