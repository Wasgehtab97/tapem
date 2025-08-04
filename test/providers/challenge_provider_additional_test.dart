import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/providers/challenge_provider.dart';
import 'package:tapem/features/challenges/domain/models/challenge.dart';
import 'package:tapem/features/challenges/domain/models/completed_challenge.dart';
import 'package:tapem/features/challenges/domain/models/badge.dart';
import 'package:tapem/features/challenges/domain/repositories/challenge_repository.dart';

class FakeChallengeRepository implements ChallengeRepository {
  final activeCtrl = StreamController<List<Challenge>>.broadcast();
  final completedCtrl = StreamController<List<CompletedChallenge>>.broadcast();
  final badgeCtrl = StreamController<List<Badge>>.broadcast();
  int checkCalls = 0;

  @override
  Stream<List<Challenge>> watchActiveChallenges(String gymId) =>
      activeCtrl.stream;

  @override
  Stream<List<CompletedChallenge>> watchCompletedChallenges(
    String gymId,
    String userId,
  ) =>
      completedCtrl.stream;

  @override
  Stream<List<Badge>> watchBadges(String userId) => badgeCtrl.stream;

  @override
  Future<void> checkChallenges(String gymId, String userId, String deviceId) async {
    checkCalls++;
  }

  void dispose() {
    activeCtrl.close();
    completedCtrl.close();
    badgeCtrl.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChallengeProvider', () {
    test('watchChallenges filters completed', () async {
      final repo = FakeChallengeRepository();
      final provider = ChallengeProvider(repo: repo);
      provider.watchChallenges('g1', 'u1');
      repo.activeCtrl.add([
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
      ]);
      repo.completedCtrl.add([
        CompletedChallenge(id: 'c1', title: 'A', completedAt: DateTime(2024))
      ]);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.challenges.map((c) => c.id), ['c2']);
      provider.dispose();
      repo.dispose();
    });

    test('watchBadges updates list', () async {
      final repo = FakeChallengeRepository();
      final provider = ChallengeProvider(repo: repo);
      provider.watchBadges('u1');
      repo.badgeCtrl.add([
        Badge(
          id: 'b1',
          challengeId: 'c1',
          userId: 'u1',
          awardedAt: DateTime(2024),
        ),
      ]);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.badges.length, 1);
      provider.dispose();
      repo.dispose();
    });

    test('checkChallenges delegates to repository', () async {
      final repo = FakeChallengeRepository();
      final provider = ChallengeProvider(repo: repo);
      await provider.checkChallenges('g1', 'u1', 'd1');
      expect(repo.checkCalls, 1);
      repo.dispose();
    });
  });
}
