import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/providers/challenge_provider.dart';
import 'package:tapem/features/challenges/domain/models/challenge.dart';
import 'package:tapem/features/challenges/domain/models/completed_challenge.dart';
import 'package:tapem/features/challenges/domain/models/badge.dart';
import 'package:tapem/features/challenges/domain/repositories/challenge_repository.dart';

class FakeChallengeRepository implements ChallengeRepository {
  List<Challenge> active = [];
  List<CompletedChallenge> completed = [];
  List<Badge> badges = [];
  int checkCalls = 0;

  @override
  Future<List<Challenge>> fetchActiveChallenges(String gymId) async => active;

  @override
  Future<List<CompletedChallenge>> fetchCompletedChallenges(
    String gymId,
    String userId,
  ) async =>
      completed;

  @override
  Future<List<Badge>> fetchBadges(String userId) async => badges;

  @override
  Future<void> checkChallenges(String gymId, String userId, String deviceId) async {
    checkCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChallengeProvider', () {
    test('watchChallenges filters completed', () async {
      final repo = FakeChallengeRepository();
      final provider = ChallengeProvider(repo: repo);
      repo.active = [
        Challenge(
          id: 'c1',
          title: 'A',
          start: DateTime(2024),
          end: DateTime(2024),
          deviceIds: const [],
        ),
        Challenge(
          id: 'c2',
          title: 'B',
          start: DateTime(2024),
          end: DateTime(2024),
          deviceIds: const [],
        ),
      ];
      repo.completed = [
        CompletedChallenge(id: 'c1', title: 'A', completedAt: DateTime(2024))
      ];
      provider.watchChallenges('g1', 'u1');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.challenges.map((c) => c.id), ['c2']);
      provider.dispose();
    });

    test('watchBadges updates list', () async {
      final repo = FakeChallengeRepository();
      final provider = ChallengeProvider(repo: repo);
      repo.badges = [
        Badge(
          id: 'b1',
          challengeId: 'c1',
          userId: 'u1',
          awardedAt: DateTime(2024),
        ),
      ];
      provider.watchBadges('u1');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.badges.length, 1);
      provider.dispose();
    });

    test('checkChallenges delegates to repository', () async {
      final repo = FakeChallengeRepository();
      final provider = ChallengeProvider(repo: repo);
      await provider.checkChallenges('g1', 'u1', 'd1');
      expect(repo.checkCalls, 1);
    });
  });
}
