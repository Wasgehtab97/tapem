import '../../data/repositories/auth_repository_impl.dart';
import '../models/user_data.dart';

class RegisterUseCase {
  final AuthRepositoryImpl _repo;
  RegisterUseCase([AuthRepositoryImpl? repo])
      : _repo = repo ?? AuthRepositoryImpl();

  Future<UserData> execute(
          String email, String password, String gymId) =>
      _repo.register(email, password, gymId);
}
