import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/data/services/username_service.dart';

void main() {
  group('changeUsernameTransaction', () {
    test('successfully changes to free name', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('users').doc('u1').set({
        'username': 'Old',
        'usernameLower': 'old',
      });
      await fs.collection('usernames').doc('old').set({
        'uid': 'u1',
        'createdAt': Timestamp.now(),
      });

      await changeUsernameTransaction(
        firestore: fs,
        uid: 'u1',
        newUsername: 'Alice',
      );

      final user = await fs.collection('users').doc('u1').get();
      expect(user.data()!['username'], 'Alice');
      expect(user.data()!['usernameLower'], 'alice');
      final mapping = await fs.collection('usernames').doc('alice').get();
      expect(mapping.data()!['uid'], 'u1');
      expect(mapping.data()!.keys, unorderedEquals(['uid', 'createdAt']));
      final old = await fs.collection('usernames').doc('old').get();
      expect(old.exists, isFalse);
    });

    test('throws when name taken by another uid', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('users').doc('u1').set({
        'username': 'Old',
        'usernameLower': 'old',
      });
      await fs.collection('usernames').doc('old').set({
        'uid': 'u1',
        'createdAt': Timestamp.now(),
      });
      await fs.collection('usernames').doc('alice').set({
        'uid': 'other',
        'createdAt': Timestamp.now(),
      });

      expect(
        () => changeUsernameTransaction(
          firestore: fs,
          uid: 'u1',
          newUsername: 'Alice',
        ),
        throwsA(isA<FirebaseException>().having((e) => e.code, 'code', 'username_taken')),
      );
      final user = await fs.collection('users').doc('u1').get();
      expect(user.data()!['usernameLower'], 'old');
      final mapping = await fs.collection('usernames').doc('alice').get();
      expect(mapping.data()!['uid'], 'other');
    });

    test('self-same mapping is no-op', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('users').doc('u1').set({
        'username': 'Old',
        'usernameLower': 'old',
      });
      await fs.collection('usernames').doc('old').set({
        'uid': 'u1',
        'createdAt': Timestamp.fromMillisecondsSinceEpoch(1),
      });
      await fs.collection('usernames').doc('alice').set({
        'uid': 'u1',
        'createdAt': Timestamp.fromMillisecondsSinceEpoch(2),
      });

      await changeUsernameTransaction(
        firestore: fs,
        uid: 'u1',
        newUsername: 'Alice',
      );

      final user = await fs.collection('users').doc('u1').get();
      expect(user.data()!['usernameLower'], 'old');
      final newDoc = await fs.collection('usernames').doc('alice').get();
      expect(newDoc.data()!['createdAt'], Timestamp.fromMillisecondsSinceEpoch(2));
      final oldDoc = await fs.collection('usernames').doc('old').get();
      expect(oldDoc.exists, isTrue);
    });
  });
}
