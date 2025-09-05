import '../repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

class SetAvatarKeyUseCase {
  final AuthRepository _repo;
  SetAvatarKeyUseCase([AuthRepository? repo])
      : _repo = repo ?? AuthRepositoryImpl();

  Future<void> execute(String userId, String avatarKey) {
    return _repo.setAvatarKey(userId, avatarKey);
  }
}
