// lib/domain/usecases/profile/fetch_user_profile.dart

import 'package:tapem/domain/repositories/profile_repository.dart';

/// Holt das Nutzerprofil als Map.
///
/// [userId] – Die ID des aktuellen Nutzers.
/// Rückgabe: Ein Map mit Profilfeldern (z. B. displayName, email, gymId).
class FetchUserProfileUseCase {
  final ProfileRepository _repository;

  FetchUserProfileUseCase(this._repository);

  Future<Map<String, dynamic>> call(String userId) async {
    return await _repository.fetchUserProfile(userId);
  }
}
