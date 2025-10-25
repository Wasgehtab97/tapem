import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/data/dtos/user_data_dto.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';

import '../../helpers/fake_firestore.dart';

void main() {
  group('UserDataDto', () {
    late FakeFirebaseFirestore firestore;
    late Timestamp now;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      now = Timestamp.fromDate(DateTime(2023, 5, 1));
      await firestore.seedDocument('users/user-1', {
        'email': 'user@example.com',
        'username': 'Hero',
        'usernameLower': 'hero',
        'gymCodes': ['gym-1'],
        'showInLeaderboard': true,
        'publicProfile': false,
        'role': 'member',
        'createdAt': now,
        'avatarKey': 'avatar-1',
      });
    });

    test('fromDocument reads Firestore data and falls back to emailLower', () async {
      final snap = await firestore.collection('users').doc('user-1').get();
      final dto = UserDataDto.fromDocument(snap);

      expect(dto.userId, 'user-1');
      expect(dto.email, 'user@example.com');
      expect(dto.emailLower, 'user@example.com');
      expect(dto.userName, 'Hero');
      expect(dto.userNameLower, 'hero');
      expect(dto.gymCodes, ['gym-1']);
      expect(dto.showInLeaderboard, isTrue);
      expect(dto.publicProfile, isFalse);
      expect(dto.role, 'member');
      expect(dto.createdAt, now.toDate());
      expect(dto.avatarKey, 'avatar-1');
    });

    test('toJson only includes optional username fields when available', () {
      final dto = UserDataDto(
        userId: 'user-2',
        email: 'user2@example.com',
        emailLower: 'user2@example.com',
        gymCodes: const ['g1', 'g2'],
        showInLeaderboard: false,
        publicProfile: true,
        role: 'coach',
        createdAt: DateTime(2023, 6, 1),
        avatarKey: 'avatar-2',
      );

      final json = dto.toJson();
      expect(json, {
        'email': 'user2@example.com',
        'emailLower': 'user2@example.com',
        'gymCodes': ['g1', 'g2'],
        'showInLeaderboard': false,
        'publicProfile': true,
        'role': 'coach',
        'createdAt': Timestamp.fromDate(DateTime(2023, 6, 1)),
        'avatarKey': 'avatar-2',
      });
    });

    test('toModel returns equivalent UserData', () {
      final dto = UserDataDto(
        userId: 'user-3',
        email: 'user3@example.com',
        emailLower: 'user3@example.com',
        userName: 'User 3',
        userNameLower: 'user 3',
        gymCodes: const ['g1'],
        showInLeaderboard: true,
        publicProfile: true,
        role: 'member',
        createdAt: DateTime(2023, 7, 1),
        avatarKey: 'avatar-3',
      );

      final model = dto.toModel();
      expect(
        model,
        isA<UserData>()
            .having((u) => u.id, 'id', 'user-3')
            .having((u) => u.email, 'email', 'user3@example.com')
            .having((u) => u.userName, 'userName', 'User 3')
            .having((u) => u.gymCodes, 'gymCodes', ['g1'])
            .having((u) => u.showInLeaderboard, 'showInLeaderboard', true)
            .having((u) => u.publicProfile, 'publicProfile', true)
            .having((u) => u.role, 'role', 'member')
            .having((u) => u.createdAt, 'createdAt', DateTime(2023, 7, 1))
            .having((u) => u.avatarKey, 'avatarKey', 'avatar-3'),
      );
    });
  });
}
