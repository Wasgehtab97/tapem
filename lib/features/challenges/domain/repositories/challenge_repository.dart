import '../models/challenge.dart';
import '../models/badge.dart';
import '../models/completed_challenge.dart';

abstract class ChallengeRepository {
  Stream<List<Challenge>> watchActiveChallenges(String gymId);
  Stream<List<Badge>> watchBadges(String userId);
  Stream<List<CompletedChallenge>> watchCompletedChallenges(
    String gymId,
    String userId,
  );
}
