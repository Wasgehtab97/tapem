import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';

void main() {
  group('UserData.copyWith', () {
    final base = UserData(
      id: 'uid-1',
      email: 'user@example.com',
      userName: 'User',
      gymCodes: const ['gym1'],
      showInLeaderboard: true,
      publicProfile: false,
      role: 'member',
      createdAt: DateTime(2023, 1, 1),
      avatarKey: 'avatar-1',
    );

    test('returns new instance with updated fields', () {
      final result = base.copyWith(
        email: 'new@example.com',
        userName: 'New Name',
        gymCodes: const ['gym1', 'gym2'],
        showInLeaderboard: false,
        publicProfile: true,
        role: 'admin',
        createdAt: DateTime(2024, 1, 1),
        avatarKey: 'avatar-2',
      );

      expect(result.email, 'new@example.com');
      expect(result.userName, 'New Name');
      expect(result.gymCodes, ['gym1', 'gym2']);
      expect(result.showInLeaderboard, isFalse);
      expect(result.publicProfile, isTrue);
      expect(result.role, 'admin');
      expect(result.createdAt, DateTime(2024, 1, 1));
      expect(result.avatarKey, 'avatar-2');
    });

    test('keeps original values when null is provided', () {
      final result = base.copyWith();

      expect(result.id, base.id);
      expect(result.email, base.email);
      expect(result.userName, base.userName);
      expect(result.gymCodes, base.gymCodes);
      expect(result.showInLeaderboard, base.showInLeaderboard);
      expect(result.publicProfile, base.publicProfile);
      expect(result.role, base.role);
      expect(result.createdAt, base.createdAt);
      expect(result.avatarKey, base.avatarKey);
    });
  });
}
