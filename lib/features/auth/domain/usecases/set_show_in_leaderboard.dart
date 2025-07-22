import '../repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

class SetShowInLeaderboardUseCase {
  final AuthRepository _repo;
  SetShowInLeaderboardUseCase([AuthRepository? repo])
      : _repo = repo ?? AuthRepositoryImpl();

  Future<void> execute(String userId, bool value) {
    return _repo.setShowInLeaderboard(userId, value);
  }
}
