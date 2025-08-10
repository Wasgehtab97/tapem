import '../repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

class SetUsernameUseCase {
  final AuthRepository _repo;
  SetUsernameUseCase(AuthRepository repo) : _repo = repo;

  Future<void> execute(String userId, String username) {
    return _repo.setUsername(userId, username);
  }
}
