import '../../data/repositories/auth_repository_impl.dart';

class LogoutUseCase {
  final AuthRepositoryImpl _repo;
  LogoutUseCase([AuthRepositoryImpl? repo])
    : _repo = repo ?? AuthRepositoryImpl();

  Future<void> execute() => _repo.logout();
}
