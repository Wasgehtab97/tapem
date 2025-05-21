import '../../data/repositories/auth_repository_impl.dart';
import '../models/user_data.dart';

class LoginUseCase {
  final AuthRepositoryImpl _repo;
  LoginUseCase([AuthRepositoryImpl? repo])
      : _repo = repo ?? AuthRepositoryImpl();

  Future<UserData> execute(String email, String password) =>
      _repo.login(email, password);
}
