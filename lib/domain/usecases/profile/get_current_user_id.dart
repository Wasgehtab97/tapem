// lib/domain/usecases/profile/get_current_user_id.dart

import 'package:tapem/domain/repositories/profile_repository.dart';

/// Liest die ID des aktuell eingeloggten Nutzers (für Profilzugriffe).
///
/// Rückgabe: Die User-ID oder `null`, wenn kein Nutzer eingeloggt ist.
class GetCurrentUserIdProfileUseCase {
  final ProfileRepository _repository;

  GetCurrentUserIdProfileUseCase(this._repository);

  Future<String?> call() async {
    return await _repository.getCurrentUserId();
  }
}
