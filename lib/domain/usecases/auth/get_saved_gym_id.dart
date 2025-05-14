// lib/domain/usecases/auth/get_saved_gym_id.dart

import 'package:tapem/domain/repositories/auth_repository.dart';

/// UseCase zum Auslesen der zwischengespeicherten Gym-ID.
class GetSavedGymIdUseCase {
  final AuthRepository _repository;

  GetSavedGymIdUseCase(this._repository);

  /// Gibt die gespeicherte Gym-ID zurück oder `null`, falls keine vorhanden.
  Future<String?> call() async {
    return await _repository.getSavedGymId();
  }
}
