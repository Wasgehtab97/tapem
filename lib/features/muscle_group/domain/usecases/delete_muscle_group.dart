import '../repositories/muscle_group_repository.dart';

class DeleteMuscleGroup {
  final MuscleGroupRepository _repo;
  DeleteMuscleGroup(this._repo);

  Future<void> execute(String gymId, String groupId) =>
      _repo.deleteMuscleGroup(gymId, groupId);
}
