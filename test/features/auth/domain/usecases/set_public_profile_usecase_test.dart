import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/domain/usecases/set_public_profile.dart';

import '../../helpers/fakes.dart';

void main() {
  group('SetPublicProfileUseCase', () {
    test('delegates to repository', () async {
      bool? newValue;
      final repo = FakeAuthRepository(onSetPublicProfile: (_, value) async {
        newValue = value;
      });
      final useCase = SetPublicProfileUseCase(repo);

      await useCase.execute('uid', true);
      expect(newValue, isTrue);
    });

    test('propagates repository errors', () async {
      final repo = FakeAuthRepository(onSetPublicProfile: (_, __) => Future<void>.error(Exception('failure')));
      final useCase = SetPublicProfileUseCase(repo);

      expect(() => useCase.execute('uid', false), throwsA(isA<Exception>()));
    });

    test('throws ArgumentError for invalid user id', () async {
      final repo = FakeAuthRepository(onSetPublicProfile: (userId, value) async {
        if (userId.isEmpty) {
          throw ArgumentError('userId required');
        }
      });
      final useCase = SetPublicProfileUseCase(repo);

      expect(() => useCase.execute('', true), throwsA(isA<ArgumentError>()));
    });
  });
}
