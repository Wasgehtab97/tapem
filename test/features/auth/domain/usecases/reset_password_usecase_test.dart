import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/domain/usecases/reset_password.dart';

import '../../helpers/fakes.dart';

void main() {
  group('ResetPasswordUseCase', () {
    test('delegates to repository', () async {
      String? email;
      final repo = FakeAuthRepository(onSendPasswordResetEmail: (value) async {
        email = value;
      });
      final useCase = ResetPasswordUseCase(repo);

      await useCase.execute('user@example.com');
      expect(email, 'user@example.com');
    });

    test('propagates repository errors', () async {
      final repo = FakeAuthRepository(onSendPasswordResetEmail: (_) => Future<void>.error(Exception('failure')));
      final useCase = ResetPasswordUseCase(repo);

      expect(() => useCase.execute('user@example.com'), throwsA(isA<Exception>()));
    });

    test('throws ArgumentError for invalid email', () async {
      final repo = FakeAuthRepository(onSendPasswordResetEmail: (email) async {
        if (email.isEmpty) {
          throw ArgumentError('email required');
        }
      });
      final useCase = ResetPasswordUseCase(repo);

      expect(() => useCase.execute(''), throwsA(isA<ArgumentError>()));
    });
  });
}
