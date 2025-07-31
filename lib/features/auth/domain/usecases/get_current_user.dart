import '../../data/repositories/auth_repository_impl.dart';
import '../models/user_data.dart';

class GetCurrentUserUseCase {
  final AuthRepositoryImpl _repo;
  GetCurrentUserUseCase([AuthRepositoryImpl? repo])
    : _repo = repo ?? AuthRepositoryImpl();

  Future<UserData?> execute() => _repo.getCurrentUser();
}
