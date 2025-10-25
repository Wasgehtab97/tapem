import '../../data/repositories/auth_repository_impl.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository _repo;
  LogoutUseCase([AuthRepository? repo])
    : _repo = repo ?? AuthRepositoryImpl();

  Future<void> execute() => _repo.logout();
}
