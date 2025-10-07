import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tapem/features/auth/data/services/username_service.dart';
import 'package:tapem/features/auth/data/sources/firestore_auth_source.dart';

class _MockChangeUsernameRunner extends Mock implements ChangeUsernameRunner {}

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {}

void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  group('FirestoreAuthSource.setUsername', () {
    test('retries once when transaction is resource-exhausted', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u1').set({});
      final runner = _MockChangeUsernameRunner();
      var callCount = 0;
      when(() => runner(
            firestore: firestore,
            uid: any(named: 'uid'),
            newUsername: any(named: 'newUsername'),
          )).thenAnswer((invocation) async {
        callCount += 1;
        if (callCount == 1) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'resource-exhausted',
          );
        }
        await changeUsernameTransaction(
          firestore: invocation.namedArguments[#firestore] as FirebaseFirestore,
          uid: invocation.namedArguments[#uid] as String,
          newUsername: invocation.namedArguments[#newUsername] as String,
        );
      });

      final source = FirestoreAuthSource(
        auth: _FakeFirebaseAuth(),
        firestore: firestore,
        changeUsername: runner,
      );

      await source.setUsername('u1', 'Alice');

      expect(callCount, 2);
      final userDoc = await firestore.collection('users').doc('u1').get();
      expect(userDoc.data()!['username'], 'Alice');
    });

    test('throws after max retries when resource-exhausted persists', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u1').set({});
      final runner = _MockChangeUsernameRunner();
      when(() => runner(
            firestore: firestore,
            uid: any(named: 'uid'),
            newUsername: any(named: 'newUsername'),
          )).thenThrow(
        FirebaseException(plugin: 'firestore', code: 'resource-exhausted'),
      );

      final source = FirestoreAuthSource(
        auth: _FakeFirebaseAuth(),
        firestore: firestore,
        changeUsername: runner,
      );

      await expectLater(
        source.setUsername('u1', 'Alice'),
        throwsA(isA<FirebaseException>().having((e) => e.code, 'code', 'resource-exhausted')),
      );

      verify(() => runner(
            firestore: firestore,
            uid: any(named: 'uid'),
            newUsername: any(named: 'newUsername'),
          )).called(3);
    });
  });
}
