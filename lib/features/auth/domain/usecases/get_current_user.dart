import '../../data/repositories/auth_repository_impl.dart';
import '../models/user_data.dart';

class GetCurrentUserUseCase {
  final AuthRepositoryImpl _repo;
  GetCurrentUserUseCase(this._repo);

  Future<UserData?> execute() => _repo.getCurrentUser();
}
