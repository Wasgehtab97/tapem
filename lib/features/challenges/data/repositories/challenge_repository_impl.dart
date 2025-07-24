import '../../domain/repositories/challenge_repository.dart';
import '../sources/firestore_challenge_source.dart';
import '../../domain/models/challenge.dart';
import '../../domain/models/badge.dart';
import '../../domain/models/completed_challenge.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  final FirestoreChallengeSource _source;
  ChallengeRepositoryImpl(this._source);

  @override
  Stream<List<Challenge>> watchActiveChallenges(String gymId) {
    return _source.watchActiveChallenges(gymId);
  }

  @override
  Stream<List<Badge>> watchBadges(String userId) {
    return _source.watchBadges(userId);
  }

  @override
  Stream<List<CompletedChallenge>> watchCompletedChallenges(
      String gymId, String userId) {
    return _source.watchCompletedChallenges(gymId, userId);
  }

  @override
  Future<void> checkChallenges(
      String gymId, String userId, String deviceId) {
    return _source.checkChallenges(
      gymId: gymId,
      userId: userId,
      deviceId: deviceId,
    );
  }
}
