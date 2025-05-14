// lib/domain/usecases/auth/login.dart

import 'package:tapem/domain/repositories/auth_repository.dart';

/// UseCase zum Einloggen eines Nutzers.
class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  /// Meldet mit [email] und [password] an.
  Future<void> call({
    required String email,
    required String password,
  }) async {
    await _repository.login(
      email: email,
      password: password,
    );
  }
}
