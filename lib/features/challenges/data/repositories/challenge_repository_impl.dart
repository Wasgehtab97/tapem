import '../../domain/repositories/challenge_repository.dart';
import '../sources/firestore_challenge_source.dart';
import '../../domain/models/challenge.dart';
import '../../domain/models/badge.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  final FirestoreChallengeSource _source;
  ChallengeRepositoryImpl(this._source);

  @override
  Stream<List<Challenge>> watchActiveChallenges() {
    return _source.watchActiveChallenges();
  }

  @override
  Stream<List<Badge>> watchBadges(String userId) {
    return _source.watchBadges(userId);
  }
}
