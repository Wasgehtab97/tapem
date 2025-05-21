// lib/features/gym/domain/usecases/validate_gym_code.dart
import '../models/gym_config.dart';
import '../repositories/gym_repository.dart';

/// Exception, wenn kein Gym für den Code gefunden wird.
class GymNotFoundException implements Exception {
  final String message;
  GymNotFoundException([this.message = 'Gym not found for given code.']);
}

class ValidateGymCode {
  final GymRepository _repository;

  ValidateGymCode(this._repository);

  /// Wirft [GymNotFoundException], wenn der Code ungültig ist.
  Future<GymConfig> execute(String code) async {
    final gym = await _repository.getGymByCode(code);
    if (gym == null) throw GymNotFoundException();
    return gym;
  }
}
