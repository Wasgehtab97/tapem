import '../../data/repositories/auth_repository_impl.dart';
import '../models/user_data.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository _repo;
  GetCurrentUserUseCase([AuthRepository? repo])
    : _repo = repo ?? AuthRepositoryImpl();

  Future<UserData?> execute() => _repo.getCurrentUser();
}
