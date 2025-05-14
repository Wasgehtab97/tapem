// lib/domain/usecases/profile/sign_out.dart

import 'package:tapem/domain/repositories/profile_repository.dart';

/// Meldet den aktuellen Nutzer ab (Profil-Kontext).
///
/// Rückgabe: `void`.
class SignOutUseCase {
  final ProfileRepository _repository;

  SignOutUseCase(this._repository);

  Future<void> call() async {
    await _repository.signOut();
  }
}
