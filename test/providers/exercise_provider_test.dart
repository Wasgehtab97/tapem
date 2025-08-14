import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/providers/exercise_provider.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/domain/repositories/exercise_repository.dart';
import 'package:tapem/features/device/domain/usecases/create_exercise_usecase.dart';
import 'package:tapem/features/device/domain/usecases/delete_exercise_usecase.dart';
import 'package:tapem/features/device/domain/usecases/get_exercises_for_device.dart';
import 'package:tapem/features/device/domain/usecases/update_exercise_usecase.dart';
import 'package:tapem/features/device/domain/usecases/update_exercise_muscle_groups_usecase.dart';

class _FakeExerciseRepo implements ExerciseRepository {
  List<Exercise> exercises;
  List<String>? lastPrimary;
  List<String>? lastSecondary;
  _FakeExerciseRepo(this.exercises);
  @override
  Future<List<Exercise>> getExercises(
      String gymId, String deviceId, String userId) async => exercises;
  @override
  Future<void> createExercise(String gymId, String deviceId, Exercise ex) async {}
  @override
  Future<void> updateExercise(String gymId, String deviceId, Exercise ex) async {}
  @override
  Future<void> deleteExercise(
      String gymId, String deviceId, String exerciseId, String userId) async {}
  @override
  Future<void> updateMuscleGroups(String gymId, String deviceId, String exerciseId,
      List<String> primaryGroups, List<String> secondaryGroups) async {
    lastPrimary = primaryGroups;
    lastSecondary = secondaryGroups;
    final idx = exercises.indexWhere((e) => e.id == exerciseId);
    if (idx != -1) {
      exercises[idx] = exercises[idx].copyWith(
        primaryMuscleGroupIds: primaryGroups,
        secondaryMuscleGroupIds: secondaryGroups,
      );
    }
  }
}

void main() {
  test('updateMuscleGroups replaces arrays and updates state', () async {
    final repo = _FakeExerciseRepo([
      Exercise(id: 'e1', name: 'Ex', userId: 'u1'),
    ]);
    final provider = ExerciseProvider(
      getEx: GetExercisesForDevice(repo),
      createEx: CreateExerciseUseCase(repo),
      deleteEx: DeleteExerciseUseCase(repo),
      updateEx: UpdateExerciseUseCase(repo),
      updateMuscles: UpdateExerciseMuscleGroupsUseCase(repo),
    );
    await provider.loadExercises('g', 'd', 'u1');
    await provider.updateMuscleGroups(
        'g', 'd', 'e1', 'u1', ['1'], ['2']);
    expect(repo.lastPrimary, ['1']);
    expect(repo.lastSecondary, ['2']);
    expect(provider.exercises.first.primaryMuscleGroupIds, ['1']);
    expect(provider.exercises.first.secondaryMuscleGroupIds, ['2']);
  });
}
