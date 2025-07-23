import '../models/challenge.dart';
import '../models/badge.dart';

abstract class ChallengeRepository {
  Stream<List<Challenge>> watchActiveChallenges(String gymId);
  Stream<List<Badge>> watchBadges(String userId);
}
