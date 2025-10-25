import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';
import 'package:tapem/features/auth/domain/usecases/login.dart';

import '../../helpers/fakes.dart';

void main() {
  group('LoginUseCase', () {
    final user = UserData(
      id: 'uid-1',
      email: 'user@example.com',
      userName: null,
      gymCodes: const ['gym'],
      showInLeaderboard: true,
      publicProfile: false,
      role: 'member',
      createdAt: DateTime(2023, 1, 1),
    );

    test('returns user and refreshes Firebase token on success', () async {
      final fakeRepo = FakeAuthRepository(onLogin: (email, password) async {
        expect(email, 'user@example.com');
        expect(password, 'secret');
        return user;
      });
      final firebaseUser = FakeFirebaseUser(uid: 'uid-1', email: 'user@example.com');
      final authManager = FakeFirebaseAuthManager(currentUser: firebaseUser);
      final useCase = LoginUseCase(repo: fakeRepo, authManager: authManager);

      final result = await useCase.execute('user@example.com', 'secret');

      expect(result, same(user));
      expect(authManager.reloadCalls, 1);
      expect(authManager.forceRefreshCalls, 1);
    });

    test('propagates repository errors', () async {
      final fakeRepo = FakeAuthRepository(
        onLogin: (_, __) => Future<UserData>.error(Exception('failure')),
      );
      final authManager = FakeFirebaseAuthManager(currentUser: FakeFirebaseUser(uid: 'uid', email: 'user@example.com'));
      final useCase = LoginUseCase(repo: fakeRepo, authManager: authManager);

      expect(
        () => useCase.execute('user@example.com', 'secret'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('failure'))),
      );
      expect(authManager.reloadCalls, 0);
    });

    test('throws ArgumentError for invalid credentials', () async {
      final fakeRepo = FakeAuthRepository(onLogin: (email, password) async {
        if (email.isEmpty || password.isEmpty) {
          throw ArgumentError('email/password required');
        }
        return user;
      });
      final useCase = LoginUseCase(repo: fakeRepo, authManager: FakeFirebaseAuthManager());

      expect(
        () => useCase.execute('', ''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
