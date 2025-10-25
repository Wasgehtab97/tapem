import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/domain/usecases/set_username.dart';

import '../../helpers/fakes.dart';

void main() {
  group('SetUsernameUseCase', () {
    test('delegates to repository', () async {
      String? updated;
      final repo = FakeAuthRepository(onSetUsername: (_, username) async {
        updated = username;
      });
      final useCase = SetUsernameUseCase(repo);

      await useCase.execute('uid', 'new');
      expect(updated, 'new');
    });

    test('propagates repository errors', () async {
      final repo = FakeAuthRepository(onSetUsername: (_, __) => Future<void>.error(Exception('failure')));
      final useCase = SetUsernameUseCase(repo);

      expect(() => useCase.execute('uid', 'new'), throwsA(isA<Exception>()));
    });

    test('throws ArgumentError for invalid username', () async {
      final repo = FakeAuthRepository(onSetUsername: (_, username) async {
        if (username.trim().isEmpty) {
          throw ArgumentError('username required');
        }
      });
      final useCase = SetUsernameUseCase(repo);

      expect(() => useCase.execute('uid', '  '), throwsA(isA<ArgumentError>()));
    });
  });
}
