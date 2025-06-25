// lib/features/gym/data/repositories/gym_repository_impl.dart
import '../../domain/models/gym_config.dart';
import '../../domain/repositories/gym_repository.dart';
import '../sources/firestore_gym_source.dart';

class GymRepositoryImpl implements GymRepository {
  final FirestoreGymSource _source;

  GymRepositoryImpl(this._source);

  @override
  Future<GymConfig?> getGymByCode(String code) {
    return _source.getGymByCode(code);
  }

  @override
  Future<GymConfig?> getGymById(String id) {
    return _source.getGymById(id);
  }
}
