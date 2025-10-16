import '../../domain/models/badge.dart';
import '../../domain/models/challenge.dart';
import '../../domain/models/completed_challenge.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../sources/firestore_challenge_source.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  ChallengeRepositoryImpl(this._source);

  final FirestoreChallengeSource _source;

  @override
  Future<List<Challenge>> fetchActiveChallenges(String gymId) {
    return _source.fetchActiveChallenges(gymId);
  }

  @override
  Future<List<Badge>> fetchBadges(String userId) {
    return _source.fetchBadges(userId);
  }

  @override
  Future<List<CompletedChallenge>> fetchCompletedChallenges(
    String gymId,
    String userId,
  ) {
    return _source.fetchCompletedChallenges(gymId, userId);
  }

  @override
  Future<void> checkChallenges(String gymId, String userId, String deviceId) {
    return _source.checkChallenges(
      gymId: gymId,
      userId: userId,
      deviceId: deviceId,
    );
  }
}
