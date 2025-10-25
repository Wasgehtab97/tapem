import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/domain/usecases/check_username_available.dart';

import '../../helpers/fakes.dart';

void main() {
  group('CheckUsernameAvailable', () {
    test('returns repository result', () async {
      final repo = FakeAuthRepository(onIsUsernameAvailable: (_) async => true);
      final useCase = CheckUsernameAvailable(repo);

      expect(await useCase.execute('name'), isTrue);
    });

    test('propagates repository errors', () async {
      final repo = FakeAuthRepository(onIsUsernameAvailable: (_) => Future<bool>.error(Exception('failure')));
      final useCase = CheckUsernameAvailable(repo);

      expect(() => useCase.execute('name'), throwsA(isA<Exception>()));
    });

    test('throws ArgumentError for invalid username', () async {
      final repo = FakeAuthRepository(onIsUsernameAvailable: (value) async {
        if (value.trim().isEmpty) {
          throw ArgumentError('username required');
        }
        return true;
      });
      final useCase = CheckUsernameAvailable(repo);

      expect(() => useCase.execute('  '), throwsA(isA<ArgumentError>()));
    });
  });
}
