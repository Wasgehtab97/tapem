import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';
import 'package:tapem/features/auth/domain/usecases/register.dart';

import '../../helpers/fakes.dart';

void main() {
  group('RegisterUseCase', () {
    final user = UserData(
      id: 'uid-2',
      email: 'new@example.com',
      userName: null,
      gymCodes: const ['gym'],
      showInLeaderboard: true,
      publicProfile: false,
      role: 'member',
      createdAt: DateTime(2023, 2, 1),
    );

    test('creates user and refreshes Firebase token', () async {
      final repo = FakeAuthRepository(
        onRegister: (email, password, gym) async {
          expect(gym, 'gym');
          return user;
        },
      );
      final firebaseUser = FakeFirebaseUser(uid: 'uid-2', email: 'new@example.com');
      final manager = FakeFirebaseAuthManager(currentUser: firebaseUser);
      final useCase = RegisterUseCase(repo: repo, authManager: manager);

      final result = await useCase.execute('new@example.com', 'secret', 'gym');
      expect(result, same(user));
      expect(manager.reloadCalls, 1);
      expect(manager.forceRefreshCalls, 1);
    });

    test('propagates registration errors', () async {
      final repo = FakeAuthRepository(
        onRegister: (_, __, ___) => Future<UserData>.error(Exception('failure')),
      );
      final useCase = RegisterUseCase(
        repo: repo,
        authManager: FakeFirebaseAuthManager(currentUser: FakeFirebaseUser(uid: 'uid', email: 'x')),
      );

      expect(
        () => useCase.execute('new@example.com', 'secret', 'gym'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('failure'))),
      );
    });

    test('throws ArgumentError for invalid gym id', () async {
      final repo = FakeAuthRepository(onRegister: (email, password, gym) async {
        if (gym.isEmpty) {
          throw ArgumentError('gym required');
        }
        return user;
      });
      final useCase = RegisterUseCase(repo: repo, authManager: FakeFirebaseAuthManager());

      expect(
        () => useCase.execute('new@example.com', 'secret', ''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
