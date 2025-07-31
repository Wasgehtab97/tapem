import '../models/muscle_group.dart';
import '../repositories/muscle_group_repository.dart';

class GetMuscleGroupsForGym {
  final MuscleGroupRepository _repo;
  GetMuscleGroupsForGym(this._repo);

  Future<List<MuscleGroup>> execute(String gymId) =>
      _repo.getMuscleGroups(gymId);
}
