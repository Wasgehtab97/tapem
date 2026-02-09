import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/xp/domain/experience_rank_signal_service.dart';

import '../../auth/helpers/fake_firestore.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExperienceRankSignalService', () {
    const gymId = 'gymA';

    late FakeFirebaseFirestore firestore;
    late ExperienceRankSignalService service;

    Future<void> seedParticipant({
      required String uid,
      required String username,
      required int xp,
      bool showInLeaderboard = true,
      String? role,
    }) async {
      await firestore.seedDocument('gyms/$gymId/users/$uid', {'joined': true});
      await firestore.seedDocument('users/$uid', {
        'username': username,
        'showInLeaderboard': showInLeaderboard,
        if (role != null) 'role': role,
      });
      await firestore.seedDocument('gyms/$gymId/users/$uid/rank/stats', {
        'dailyXP': xp,
      });
    }

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      service = ExperienceRankSignalService(firestore: firestore);

      await seedParticipant(uid: 'u1', username: 'alice', xp: 500);
      await seedParticipant(uid: 'u2', username: 'bravo', xp: 620);
      await seedParticipant(uid: 'u3', username: 'charlie', xp: 500);
      await seedParticipant(
        uid: 'u4',
        username: 'delta',
        xp: 999,
        role: 'admin',
      );
      await seedParticipant(
        uid: 'u5',
        username: 'echo',
        xp: 800,
        showInLeaderboard: false,
      );
    });

    test(
      'computes rank and xp gap while excluding hidden/admin users',
      () async {
        final signal = await service.fetch(gymId: gymId, userId: 'u1');

        expect(signal.participantCount, 3);
        expect(signal.currentRank, 2);
        expect(signal.currentXp, 500);
        expect(signal.xpToNextRank, 120);
      },
    );

    test('returns top user with zero gap', () async {
      final signal = await service.fetch(gymId: gymId, userId: 'u2');

      expect(signal.participantCount, 3);
      expect(signal.currentRank, 1);
      expect(signal.currentXp, 620);
      expect(signal.xpToNextRank, 0);
    });

    test('returns unranked signal for user outside leaderboard', () async {
      final signal = await service.fetch(gymId: gymId, userId: 'missing-user');

      expect(signal.participantCount, 3);
      expect(signal.currentRank, isNull);
      expect(signal.currentXp, 0);
      expect(signal.xpToNextRank, isNull);
    });
  });
}
