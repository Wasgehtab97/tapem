import '../models/muscle_group.dart';
import '../repositories/muscle_group_repository.dart';

class EnsureRegionGroup {
  final MuscleGroupRepository _repo;
  EnsureRegionGroup(this._repo);

  Future<String> execute(String gymId, MuscleRegion region) =>
      _repo.ensureRegionGroup(gymId, region);
}
