import '../repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

class SetProfileVisibilityUseCase {
  final AuthRepository _repo;
  SetProfileVisibilityUseCase([AuthRepository? repo])
    : _repo = repo ?? AuthRepositoryImpl();

  Future<void> execute(String userId, bool value) {
    return _repo.setProfileVisibility(userId, value);
  }
}
