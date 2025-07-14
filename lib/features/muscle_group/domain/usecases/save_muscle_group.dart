import '../models/muscle_group.dart';
import '../repositories/muscle_group_repository.dart';

class SaveMuscleGroup {
  final MuscleGroupRepository _repo;
  SaveMuscleGroup(this._repo);

  Future<void> execute(String gymId, MuscleGroup group) =>
      _repo.saveMuscleGroup(gymId, group);
}
