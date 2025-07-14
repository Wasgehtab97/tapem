import '../sources/firestore_muscle_group_source.dart';
import '../../domain/models/muscle_group.dart';
import '../../domain/repositories/muscle_group_repository.dart';

class MuscleGroupRepositoryImpl implements MuscleGroupRepository {
  final FirestoreMuscleGroupSource _source;
  MuscleGroupRepositoryImpl(this._source);

  @override
  Future<List<MuscleGroup>> getMuscleGroups(String gymId) async {
    final dtos = await _source.getMuscleGroups(gymId);
    return dtos.map((d) => d.toModel()).toList();
  }

  @override
  Future<void> saveMuscleGroup(String gymId, MuscleGroup group) {
    return _source.saveMuscleGroup(gymId, group);
  }
}
