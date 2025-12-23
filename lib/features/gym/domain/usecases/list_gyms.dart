// lib/features/gym/domain/usecases/list_gyms.dart
import '../models/gym_config.dart';
import '../repositories/gym_repository.dart';

class ListGyms {
  final GymRepository _repository;
  ListGyms(this._repository);

  Future<List<GymConfig>> execute() {
    return _repository.listGyms();
  }
}
