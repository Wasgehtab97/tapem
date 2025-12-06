import '../repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

class SetPublicKeyUseCase {
  final AuthRepository _repo;

  SetPublicKeyUseCase([AuthRepository? repo])
      : _repo = repo ?? AuthRepositoryImpl();

  Future<void> execute(String userId, String publicKey) {
    return _repo.setPublicKey(userId, publicKey);
  }
}
