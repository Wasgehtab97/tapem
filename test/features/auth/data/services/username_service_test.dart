import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/data/services/username_service.dart';

import '../../helpers/fake_firestore.dart';

void main() {
  group('changeUsernameTransaction', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      firestore.seedDocument('users/uid-1', {
        'username': 'old name',
        'usernameLower': 'old name',
      });
      firestore.seedDocument('usernames/old name', {
        'uid': 'uid-1',
      });
    });

    test('updates username mapping and removes old record', () async {
      await changeUsernameTransaction(
        firestore: firestore,
        uid: 'uid-1',
        newUsername: 'New  Name ',
      );

      final newMapping = await firestore.collection('usernames').doc('new name').get();
      expect(newMapping.exists, isTrue);
      expect(newMapping.data(), containsPair('uid', 'uid-1'));

      final oldMapping = await firestore.collection('usernames').doc('old name').get();
      expect(oldMapping.exists, isFalse);

      final userDoc = await firestore.collection('users').doc('uid-1').get();
      expect(userDoc.data(), containsPair('username', 'New Name'));
      expect(userDoc.data(), containsPair('usernameLower', 'new name'));
    });

    test('throws when desired username is already taken by another user', () async {
      firestore.seedDocument('usernames/new name', {
        'uid': 'other-user',
      });

      expect(
        () => changeUsernameTransaction(
          firestore: firestore,
          uid: 'uid-1',
          newUsername: 'new name',
        ),
        throwsA(isA<FirebaseException>().having((e) => e.code, 'code', 'username_taken')),
      );
    });

    test('throws when user document does not exist', () async {
      expect(
        () => changeUsernameTransaction(
          firestore: firestore,
          uid: 'missing',
          newUsername: 'anyone',
        ),
        throwsA(isA<FirebaseException>().having((e) => e.code, 'code', 'user_not_found')),
      );
    });

    test('returns immediately when username is unchanged', () async {
      await changeUsernameTransaction(
        firestore: firestore,
        uid: 'uid-1',
        newUsername: 'old name',
      );

      final newMapping = await firestore.collection('usernames').doc('old name').get();
      expect(newMapping.exists, isTrue);
      expect(newMapping.data(), containsPair('uid', 'uid-1'));
    });
  });
}
