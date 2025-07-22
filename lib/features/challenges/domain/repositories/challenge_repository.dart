import '../models/challenge.dart';
import '../models/badge.dart';

abstract class ChallengeRepository {
  Stream<List<Challenge>> watchActiveChallenges();
  Stream<List<Badge>> watchBadges(String userId);
}
