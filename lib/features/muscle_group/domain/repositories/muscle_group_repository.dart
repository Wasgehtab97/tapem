import '../models/muscle_group.dart';

abstract class MuscleGroupRepository {
  Future<List<MuscleGroup>> getMuscleGroups(String gymId);
  Future<void> saveMuscleGroup(String gymId, MuscleGroup group);
}
