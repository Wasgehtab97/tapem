import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/domain/repositories/exercise_repository.dart';
import 'package:tapem/features/device/domain/usecases/create_exercise_usecase.dart';
import 'package:tapem/features/device/domain/usecases/delete_exercise_usecase.dart';
import 'package:tapem/features/device/domain/usecases/get_exercises_for_device.dart';
import 'package:tapem/features/device/domain/usecases/update_exercise_muscle_groups_usecase.dart';
import 'package:tapem/features/device/domain/usecases/update_exercise_usecase.dart';

class _MockExerciseRepository extends Mock implements ExerciseRepository {}

class _FakeExercise extends Fake implements Exercise {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeExercise());
  });

  group('Exercise use cases', () {
    late _MockExerciseRepository repo;

    setUp(() {
      repo = _MockExerciseRepository();
    });

    test('CreateExerciseUseCase builds exercise and forwards to repository', () async {
      when(() => repo.createExercise(any(), any(), any())).thenAnswer((_) async {});
      final useCase = CreateExerciseUseCase(repo);

      final exercise = await useCase.execute('gym', 'device', 'Test', 'user',
          primaryMuscleGroupIds: const ['p']);

      verify(() => repo.createExercise('gym', 'device', any())).called(1);
      expect(exercise.name, 'Test');
      expect(exercise.userId, 'user');
      expect(exercise.primaryMuscleGroupIds, ['p']);
      expect(exercise.id, isNotEmpty);
    });

    test('DeleteExerciseUseCase forwards to repository', () async {
      when(() => repo.deleteExercise('gym', 'device', 'exercise', 'user'))
          .thenAnswer((_) async {});
      final useCase = DeleteExerciseUseCase(repo);

      await useCase.execute('gym', 'device', 'exercise', 'user');

      verify(() => repo.deleteExercise('gym', 'device', 'exercise', 'user')).called(1);
    });

    test('GetExercisesForDevice forwards to repository', () async {
      when(() => repo.getExercises('gym', 'device', 'user')).thenAnswer((_) async => []);
      final useCase = GetExercisesForDevice(repo);

      await useCase.execute('gym', 'device', 'user');

      verify(() => repo.getExercises('gym', 'device', 'user')).called(1);
    });

    test('UpdateExerciseUseCase forwards to repository', () async {
      final exercise = Exercise(id: 'id', name: 'Test', userId: 'user');
      when(() => repo.updateExercise('gym', 'device', exercise)).thenAnswer((_) async {});
      final useCase = UpdateExerciseUseCase(repo);

      await useCase.execute('gym', 'device', exercise);

      verify(() => repo.updateExercise('gym', 'device', exercise)).called(1);
    });

    test('UpdateExerciseMuscleGroupsUseCase forwards to repository', () async {
      when(
        () => repo.updateMuscleGroups('gym', 'device', 'exercise', ['p'], ['s']),
      ).thenAnswer((_) async {});
      final useCase = UpdateExerciseMuscleGroupsUseCase(repo);

      await useCase.execute('gym', 'device', 'exercise', ['p'], ['s']);

      verify(
        () => repo.updateMuscleGroups('gym', 'device', 'exercise', ['p'], ['s']),
      ).called(1);
    });
  });
}
