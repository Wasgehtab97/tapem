// lib/domain/usecases/auth/register.dart

import 'package:tapem/domain/repositories/auth_repository.dart';

/// UseCase zur Registrierung eines neuen Nutzers.
class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  /// Registriert mit [email], [password], [displayName] und [gymId].
  Future<void> call({
    required String email,
    required String password,
    required String displayName,
    required String gymId,
  }) async {
    await _repository.register(
      email: email,
      password: password,
      displayName: displayName,
      gymId: gymId,
    );
  }
}
