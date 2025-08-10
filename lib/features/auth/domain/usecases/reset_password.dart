import '../../data/repositories/auth_repository_impl.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository _repo;
  ResetPasswordUseCase(AuthRepository repo) : _repo = repo;

  Future<void> execute(String email) => _repo.sendPasswordResetEmail(email);
}
