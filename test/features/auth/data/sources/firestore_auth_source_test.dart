import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/data/dtos/user_data_dto.dart';
import 'package:tapem/features/auth/data/sources/firestore_auth_source.dart';
import 'package:tapem/features/gym/data/sources/firestore_gym_source.dart';
import 'package:tapem/features/gym/domain/models/gym_config.dart';

import '../../helpers/fake_firestore.dart';
import '../../helpers/fakes.dart';

void main() {
  group('FirestoreAuthSource', () {
    late FakeFirebaseAuth auth;
    late FakeFirebaseFirestore firestore;
    late _FakeGymSource gymSource;
    late FirestoreAuthSource source;

    setUp(() {
      auth = FakeFirebaseAuth();
      firestore = FakeFirebaseFirestore();
      gymSource = _FakeGymSource();
      source = FirestoreAuthSource(
        auth: auth,
        firestore: firestore,
        changeUsername: _changeUsername,
        gymSource: gymSource,
      );
      gymSource.reset();
    });

    test('login fetches user document and returns dto', () async {
      final user = FakeFirebaseUser(uid: 'uid-1', email: 'user@example.com');
      auth.addUser(email: 'user@example.com', password: 'secret', user: user);
      await firestore.seedDocument('users/uid-1', {
        'email': 'user@example.com',
        'role': 'member',
        'createdAt': Timestamp.fromDate(DateTime(2023, 1, 1)),
        'gymCodes': ['gym-1'],
        'showInLeaderboard': true,
        'publicProfile': false,
      });

      final dto = await source.login('user@example.com', 'secret');
      expect(dto, isA<UserDataDto>().having((d) => d.userId, 'id', 'uid-1'));
    });

    test('login throws when user document missing', () async {
      final user = FakeFirebaseUser(uid: 'uid-2', email: 'missing@example.com');
      auth.addUser(email: 'missing@example.com', password: 'secret', user: user);

      expect(
        () => source.login('missing@example.com', 'secret'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('User document not found'))),
      );
    });

    test('register creates Firestore document and gym membership with member number', () async {
      gymSource.gyms['join-code'] = GymConfig(id: 'gym-42', code: 'join-code', name: 'Gym');

      final dto = await source.register('new@example.com', 'secret', 'join-code');

      final userDoc = await firestore.collection('users').doc(dto.userId).get();
      expect(userDoc.exists, isTrue);
      expect(userDoc.data(), containsPair('email', 'new@example.com'));

      final membership = await firestore
          .collection('gyms')
          .doc('gym-42')
          .collection('users')
          .doc(dto.userId)
          .get();
      expect(membership.exists, isTrue);
      expect(membership.data(), containsPair('memberNumber', '0001'));

      final gymDoc = await firestore.collection('gyms').doc('gym-42').get();
      expect(gymDoc.data(), containsPair('memberNumberCounter', 1));
    });

    test('register increments member number sequentially for same gym', () async {
      gymSource.gyms['join-code'] = GymConfig(id: 'gym-42', code: 'join-code', name: 'Gym');

      final first = await source.register('one@example.com', 'secret', 'join-code');
      final second = await source.register('two@example.com', 'secret', 'join-code');

      final firstMembership = await firestore
          .collection('gyms')
          .doc('gym-42')
          .collection('users')
          .doc(first.userId)
          .get();
      final secondMembership = await firestore
          .collection('gyms')
          .doc('gym-42')
          .collection('users')
          .doc(second.userId)
          .get();

      expect(firstMembership.data(), containsPair('memberNumber', '0001'));
      expect(secondMembership.data(), containsPair('memberNumber', '0002'));

      final gymDoc = await firestore.collection('gyms').doc('gym-42').get();
      expect(gymDoc.data(), containsPair('memberNumberCounter', 2));
    });

    test('register throws when gym code not found', () {
      expect(
        () => source.register('user@example.com', 'secret', 'unknown'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Gym code not found'))),
      );
    });

    test('logout signs out via FirebaseAuth', () async {
      await source.logout();
      expect(auth.signOutCalled, isTrue);
    });

    test('getCurrentUser returns null when auth has no user', () async {
      expect(await source.getCurrentUser(), isNull);
    });

    test('getCurrentUser loads dto when document exists', () async {
      final user = FakeFirebaseUser(uid: 'uid-3', email: 'user3@example.com');
      auth.addUser(email: 'user3@example.com', password: 'secret', user: user);
      await firestore.seedDocument('users/uid-3', {
        'email': 'user3@example.com',
        'role': 'member',
        'createdAt': Timestamp.fromDate(DateTime(2023, 3, 1)),
        'gymCodes': ['gym-1'],
        'showInLeaderboard': true,
        'publicProfile': false,
      });

      final dto = await source.getCurrentUser();
      expect(dto, isNotNull);
      expect(dto!.userId, 'uid-3');
    });

    test('isUsernameAvailable returns true when document missing', () async {
      final available = await source.isUsernameAvailable('some');
      expect(available, isTrue);
    });

    test('isUsernameAvailable returns false when username exists', () async {
      await firestore.seedDocument('usernames/some', {'uid': 'uid-1'});
      final available = await source.isUsernameAvailable('some');
      expect(available, isFalse);
    });

    test('setUsername delegates to change runner and retries on retryable errors', () async {
      final attempts = <int>[];
      int callCount = 0;
      Future<void> runner({
        required FirebaseFirestore firestore,
        required String uid,
        required String newUsername,
      }) async {
        attempts.add(++callCount);
        if (callCount < 2) {
          throw FirebaseException(plugin: 'firestore', code: 'aborted');
        }
      }

      final testSource = FirestoreAuthSource(
        auth: auth,
        firestore: firestore,
        changeUsername: runner,
        gymSource: gymSource,
      );

      await testSource.setUsername('uid-1', 'name');
      expect(attempts.length, 2);
    });

    test('setUsername rethrows non-retryable errors', () async {
      Future<void> runner({
        required FirebaseFirestore firestore,
        required String uid,
        required String newUsername,
      }) async {
        throw FirebaseException(plugin: 'firestore', code: 'permission-denied');
      }

      final testSource = FirestoreAuthSource(
        auth: auth,
        firestore: firestore,
        changeUsername: runner,
        gymSource: gymSource,
      );

      expect(
        () => testSource.setUsername('uid-1', 'name'),
        throwsA(isA<FirebaseException>().having((e) => e.code, 'code', 'permission-denied')),
      );
    });

    test('setShowInLeaderboard updates Firestore field', () async {
      await firestore.seedDocument('users/uid-1', {
        'showInLeaderboard': true,
      });
      await source.setShowInLeaderboard('uid-1', false);
      final doc = await firestore.collection('users').doc('uid-1').get();
      expect(doc.data(), containsPair('showInLeaderboard', false));
    });

    test('setPublicProfile updates Firestore field', () async {
      await firestore.seedDocument('users/uid-2', {
        'publicProfile': false,
      });
      await source.setPublicProfile('uid-2', true);
      final doc = await firestore.collection('users').doc('uid-2').get();
      expect(doc.data(), containsPair('publicProfile', true));
    });

    test('setAvatarKey updates Firestore field and timestamp', () async {
      await firestore.seedDocument('users/uid-4', {
        'avatarKey': 'old',
      });
      await source.setAvatarKey('uid-4', 'new');
      final doc = await firestore.collection('users').doc('uid-4').get();
      final data = doc.data();
      expect(data, containsPair('avatarKey', 'new'));
      expect(data!.containsKey('avatarUpdatedAt'), isTrue);
    });

    test('sendPasswordResetEmail delegates to FirebaseAuth', () async {
      await source.sendPasswordResetEmail('mail@example.com');
      expect(auth.passwordResetCalled, isTrue);
      expect(auth.lastPasswordResetEmail, 'mail@example.com');
    });
  });
}

Future<void> _changeUsername({
  required FirebaseFirestore firestore,
  required String uid,
  required String newUsername,
}) async {
  final users = firestore.collection('users');
  await users.doc(uid).update({'username': newUsername});
}

class _FakeGymSource extends FirestoreGymSource {
  _FakeGymSource() : super(firestore: FakeFirebaseFirestore());

  final Map<String, GymConfig> gyms = <String, GymConfig>{};

  void reset() {
    gyms.clear();
  }

  @override
  Future<GymConfig?> getGymByCode(String code) async => gyms[code];
}
