// lib/features/gym/domain/usecases/get_gym_by_id.dart
import '../models/gym_config.dart';
import '../repositories/gym_repository.dart';

class GetGymById {
  final GymRepository _repository;
  GetGymById(this._repository);

  Future<GymConfig> execute(String id) async {
    final gym = await _repository.getGymById(id);
    if (gym == null) {
      throw GymNotFoundException();
    }
    return gym;
  }
}

class GymNotFoundException implements Exception {
  final String message;
  GymNotFoundException([this.message = 'Gym not found for given id.']);
}
