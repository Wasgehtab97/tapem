import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/domain/usecases/set_avatar_key.dart';

import '../../helpers/fakes.dart';

void main() {
  group('SetAvatarKeyUseCase', () {
    test('delegates to repository', () async {
      String? avatar;
      final repo = FakeAuthRepository(onSetAvatarKey: (_, value) async {
        avatar = value;
      });
      final useCase = SetAvatarKeyUseCase(repo);

      await useCase.execute('uid', 'avatar');
      expect(avatar, 'avatar');
    });

    test('propagates repository errors', () async {
      final repo = FakeAuthRepository(onSetAvatarKey: (_, __) => Future<void>.error(Exception('failure')));
      final useCase = SetAvatarKeyUseCase(repo);

      expect(() => useCase.execute('uid', 'avatar'), throwsA(isA<Exception>()));
    });

    test('throws ArgumentError when avatar key invalid', () async {
      final repo = FakeAuthRepository(onSetAvatarKey: (_, key) async {
        if (key.isEmpty) {
          throw ArgumentError('avatar key required');
        }
      });
      final useCase = SetAvatarKeyUseCase(repo);

      expect(() => useCase.execute('uid', ''), throwsA(isA<ArgumentError>()));
    });
  });
}
