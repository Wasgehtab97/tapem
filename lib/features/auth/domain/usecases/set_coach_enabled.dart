import '../repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

class SetCoachEnabledUseCase {
  final AuthRepository _repo;

  SetCoachEnabledUseCase([AuthRepository? repo])
      : _repo = repo ?? AuthRepositoryImpl();

  Future<void> execute(String userId, bool value) {
    return _repo.setCoachEnabled(userId, value);
  }
}

