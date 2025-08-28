import '../repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

class SetPublicProfileUseCase {
  final AuthRepository _repo;
  SetPublicProfileUseCase([AuthRepository? repo])
      : _repo = repo ?? AuthRepositoryImpl();

  Future<void> execute(String userId, bool value) {
    return _repo.setPublicProfile(userId, value);
  }
}
