import '../repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

class CheckUsernameAvailable {
  final AuthRepository _repo;
  CheckUsernameAvailable(AuthRepository repo) : _repo = repo;

  Future<bool> execute(String username) {
    return _repo.isUsernameAvailable(username);
  }
}
