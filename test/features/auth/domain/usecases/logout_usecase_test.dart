import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/domain/usecases/logout.dart';

import '../../helpers/fakes.dart';

void main() {
  group('LogoutUseCase', () {
    test('delegates to repository', () async {
      var called = false;
      final repo = FakeAuthRepository(onLogout: () async {
        called = true;
      });
      final useCase = LogoutUseCase(repo);

      await useCase.execute();
      expect(called, isTrue);
    });

    test('propagates repository errors', () async {
      final repo = FakeAuthRepository(onLogout: () => Future<void>.error(Exception('failure')));
      final useCase = LogoutUseCase(repo);

      expect(
        () => useCase.execute(),
        throwsA(isA<Exception>()),
      );
    });

    test('throws ArgumentError when repository indicates invalid state', () async {
      final repo = FakeAuthRepository(onLogout: () => Future<void>.error(ArgumentError('no session')));
      final useCase = LogoutUseCase(repo);

      expect(
        () => useCase.execute(),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
