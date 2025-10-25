import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';
import 'package:tapem/features/auth/domain/usecases/get_current_user.dart';

import '../../helpers/fakes.dart';

void main() {
  group('GetCurrentUserUseCase', () {
    final user = UserData(
      id: 'uid-3',
      email: 'user@example.com',
      gymCodes: const ['gym'],
      showInLeaderboard: true,
      publicProfile: false,
      role: 'member',
      createdAt: DateTime(2023, 3, 1),
    );

    test('returns user from repository', () async {
      final repo = FakeAuthRepository(onGetCurrentUser: () async => user);
      final useCase = GetCurrentUserUseCase(repo);

      expect(await useCase.execute(), same(user));
    });

    test('returns null when repository finds no user', () async {
      final repo = FakeAuthRepository(onGetCurrentUser: () async => null);
      final useCase = GetCurrentUserUseCase(repo);

      expect(await useCase.execute(), isNull);
    });

    test('throws ArgumentError when repository reports invalid state', () async {
      final repo = FakeAuthRepository(onGetCurrentUser: () => Future<UserData?>.error(ArgumentError('invalid')));
      final useCase = GetCurrentUserUseCase(repo);

      expect(() => useCase.execute(), throwsA(isA<ArgumentError>()));
    });
  });
}
