import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/domain/usecases/set_show_in_leaderboard.dart';

import '../../helpers/fakes.dart';

void main() {
  group('SetShowInLeaderboardUseCase', () {
    test('delegates to repository', () async {
      bool? newValue;
      final repo = FakeAuthRepository(onSetShowInLeaderboard: (_, value) async {
        newValue = value;
      });
      final useCase = SetShowInLeaderboardUseCase(repo);

      await useCase.execute('uid', false);
      expect(newValue, isFalse);
    });

    test('propagates repository errors', () async {
      final repo = FakeAuthRepository(onSetShowInLeaderboard: (_, __) => Future<void>.error(Exception('failure')));
      final useCase = SetShowInLeaderboardUseCase(repo);

      expect(() => useCase.execute('uid', true), throwsA(isA<Exception>()));
    });

    test('throws ArgumentError when invalid user id provided', () async {
      final repo = FakeAuthRepository(onSetShowInLeaderboard: (userId, value) async {
        if (userId.isEmpty) {
          throw ArgumentError('userId required');
        }
      });
      final useCase = SetShowInLeaderboardUseCase(repo);

      expect(() => useCase.execute('', true), throwsA(isA<ArgumentError>()));
    });
  });
}
