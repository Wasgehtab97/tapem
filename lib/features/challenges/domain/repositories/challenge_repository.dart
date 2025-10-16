import '../models/challenge.dart';
import '../models/badge.dart';
import '../models/completed_challenge.dart';

abstract class ChallengeRepository {
  Future<List<Challenge>> fetchActiveChallenges(String gymId);
  Future<List<Badge>> fetchBadges(String userId);
  Future<List<CompletedChallenge>> fetchCompletedChallenges(
    String gymId,
    String userId,
  );

  Future<void> checkChallenges(String gymId, String userId, String deviceId);
}
