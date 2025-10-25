import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/data/dtos/user_data_dto.dart';
import 'package:tapem/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tapem/features/auth/data/sources/firestore_auth_source.dart';
import 'package:tapem/features/gym/data/sources/firestore_gym_source.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';

import '../../helpers/fake_firestore.dart';
import '../../helpers/fakes.dart';

void main() {
  group('AuthRepositoryImpl', () {
    late _StubFirestoreAuthSource source;
    late AuthRepositoryImpl repository;

    setUp(() {
      source = _StubFirestoreAuthSource();
      repository = AuthRepositoryImpl(source);
      calledEmails.clear();
    });

    test('login converts dto to model', () async {
      source.loginHandler = (_, __) async => UserDataDto(
            userId: 'user-1',
            email: 'user@example.com',
            emailLower: 'user@example.com',
            gymCodes: const [],
            showInLeaderboard: true,
            publicProfile: false,
            role: 'member',
            createdAt: DateTime(2023, 1, 1),
          );

      final user = await repository.login('user@example.com', 'secret');
      expect(user, isA<UserData>().having((u) => u.id, 'id', 'user-1'));
    });

    test('register converts dto to model', () async {
      source.registerHandler = (_, __, ___) async => UserDataDto(
            userId: 'user-2',
            email: 'user2@example.com',
            emailLower: 'user2@example.com',
            gymCodes: const ['gym'],
            showInLeaderboard: true,
            publicProfile: false,
            role: 'member',
            createdAt: DateTime(2023, 2, 1),
          );

      final user = await repository.register('user2@example.com', 'secret', 'gym');
      expect(user.id, 'user-2');
      expect(user.gymCodes, ['gym']);
    });

    test('logout delegates to source', () async {
      var called = false;
      source.logoutHandler = () async {
        called = true;
      };

      await repository.logout();
      expect(called, isTrue);
    });

    test('getCurrentUser returns null when source returns null', () async {
      source.getCurrentUserHandler = () async => null;
      final result = await repository.getCurrentUser();
      expect(result, isNull);
    });

    test('setUsername, setShowInLeaderboard, setPublicProfile, setAvatarKey delegate to source', () async {
      String? username;
      bool? leaderboard;
      bool? publicProfile;
      String? avatar;

      source.setUsernameHandler = (id, value) async {
        username = value;
      };
      source.setShowInLeaderboardHandler = (id, value) async {
        leaderboard = value;
      };
      source.setPublicProfileHandler = (id, value) async {
        publicProfile = value;
      };
      source.setAvatarKeyHandler = (id, value) async {
        avatar = value;
      };

      await repository.setUsername('user', 'new');
      await repository.setShowInLeaderboard('user', false);
      await repository.setPublicProfile('user', true);
      await repository.setAvatarKey('user', 'avatar');

      expect(username, 'new');
      expect(leaderboard, isFalse);
      expect(publicProfile, isTrue);
      expect(avatar, 'avatar');
    });

    test('isUsernameAvailable and sendPasswordResetEmail delegate to source', () async {
      source.isUsernameAvailableHandler = (_) async => true;
      source.sendPasswordResetEmailHandler = (email) async => calledEmails.add(email);

      final available = await repository.isUsernameAvailable('name');
      await repository.sendPasswordResetEmail('mail@example.com');

      expect(available, isTrue);
      expect(calledEmails, ['mail@example.com']);
    });

    test('propagates errors from source', () async {
      source.loginHandler = (_, __) async => throw Exception('failure');

      expect(
        () => repository.login('a', 'b'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('failure'))),
      );
    });
  });
}

final List<String> calledEmails = <String>[];

class _StubFirestoreAuthSource extends FirestoreAuthSource {
  _StubFirestoreAuthSource()
      : super(
          auth: FakeFirebaseAuth(),
          firestore: FakeFirebaseFirestore(),
          changeUsername: ({required firestore, required uid, required newUsername}) async {},
          gymSource: _FakeGymSource(),
        );

  Future<UserDataDto> Function(String email, String password)? loginHandler;
  Future<UserDataDto> Function(String email, String password, String gymId)?
      registerHandler;
  Future<void> Function()? logoutHandler;
  Future<UserDataDto?> Function()? getCurrentUserHandler;
  Future<void> Function(String id, String username)? setUsernameHandler;
  Future<void> Function(String id, bool value)? setShowInLeaderboardHandler;
  Future<void> Function(String id, bool value)? setPublicProfileHandler;
  Future<void> Function(String id, String avatarKey)? setAvatarKeyHandler;
  Future<bool> Function(String username)? isUsernameAvailableHandler;
  Future<void> Function(String email)? sendPasswordResetEmailHandler;

  @override
  Future<UserDataDto> login(String email, String password) {
    if (loginHandler != null) {
      return loginHandler!(email, password);
    }
    return super.login(email, password);
  }

  @override
  Future<UserDataDto> register(String email, String password, String gymId) {
    if (registerHandler != null) {
      return registerHandler!(email, password, gymId);
    }
    return super.register(email, password, gymId);
  }

  @override
  Future<void> logout() {
    if (logoutHandler != null) {
      return logoutHandler!();
    }
    return super.logout();
  }

  @override
  Future<UserDataDto?> getCurrentUser() {
    if (getCurrentUserHandler != null) {
      return getCurrentUserHandler!();
    }
    return super.getCurrentUser();
  }

  @override
  Future<void> setUsername(String userId, String username) {
    if (setUsernameHandler != null) {
      return setUsernameHandler!(userId, username);
    }
    return super.setUsername(userId, username);
  }

  @override
  Future<void> setShowInLeaderboard(String userId, bool value) {
    if (setShowInLeaderboardHandler != null) {
      return setShowInLeaderboardHandler!(userId, value);
    }
    return super.setShowInLeaderboard(userId, value);
  }

  @override
  Future<void> setPublicProfile(String userId, bool value) {
    if (setPublicProfileHandler != null) {
      return setPublicProfileHandler!(userId, value);
    }
    return super.setPublicProfile(userId, value);
  }

  @override
  Future<void> setAvatarKey(String userId, String avatarKey) {
    if (setAvatarKeyHandler != null) {
      return setAvatarKeyHandler!(userId, avatarKey);
    }
    return super.setAvatarKey(userId, avatarKey);
  }

  @override
  Future<bool> isUsernameAvailable(String username) {
    if (isUsernameAvailableHandler != null) {
      return isUsernameAvailableHandler!(username);
    }
    return super.isUsernameAvailable(username);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    if (sendPasswordResetEmailHandler != null) {
      return sendPasswordResetEmailHandler!(email);
    }
    return super.sendPasswordResetEmail(email);
  }
}

class _FakeGymSource extends FirestoreGymSource {
  _FakeGymSource() : super(firestore: FakeFirebaseFirestore());
}
