// lib/domain/usecases/auth/logout.dart

import 'package:tapem/domain/repositories/auth_repository.dart';

/// UseCase zum Ausloggen des aktuellen Nutzers.
class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  /// Meldet den aktuellen Nutzer ab.
  Future<void> call() async {
    await _repository.signOut();
  }
}
