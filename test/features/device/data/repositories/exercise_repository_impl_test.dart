import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tapem/features/device/data/repositories/exercise_repository_impl.dart';
import 'package:tapem/features/device/data/sources/firestore_exercise_source.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';

class _MockExerciseSource extends Mock implements FirestoreExerciseSource {}

void main() {
  late _MockExerciseSource source;
  late ExerciseRepositoryImpl repository;

  setUp(() {
    source = _MockExerciseSource();
    repository = ExerciseRepositoryImpl(source);
  });

  group('ExerciseRepositoryImpl', () {
    test('getExercises delegates to source', () async {
      when(() => source.getExercises('gym', 'device', 'user')).thenAnswer((_) async => []);

      await repository.getExercises('gym', 'device', 'user');

      verify(() => source.getExercises('gym', 'device', 'user')).called(1);
    });

    test('createExercise forwards to source', () async {
      final exercise = Exercise(id: 'id', name: 'Test', userId: 'user');
      when(() => source.createExercise('gym', 'device', exercise)).thenAnswer((_) async {});

      await repository.createExercise('gym', 'device', exercise);

      verify(() => source.createExercise('gym', 'device', exercise)).called(1);
    });

    test('updateExercise forwards to source', () async {
      final exercise = Exercise(id: 'id', name: 'Test', userId: 'user');
      when(() => source.updateExercise('gym', 'device', exercise)).thenAnswer((_) async {});

      await repository.updateExercise('gym', 'device', exercise);

      verify(() => source.updateExercise('gym', 'device', exercise)).called(1);
    });

    test('updateMuscleGroups forwards to source', () async {
      when(
        () => source.updateMuscleGroups(
          'gym',
          'device',
          'exercise',
          ['p1'],
          ['s1'],
        ),
      ).thenAnswer((_) async {});

      await repository.updateMuscleGroups('gym', 'device', 'exercise', ['p1'], ['s1']);

      verify(
        () => source.updateMuscleGroups(
          'gym',
          'device',
          'exercise',
          ['p1'],
          ['s1'],
        ),
      ).called(1);
    });

    test('deleteExercise forwards to source', () async {
      when(() => source.deleteExercise('gym', 'device', 'exercise'))
          .thenAnswer((_) async {});

      await repository.deleteExercise('gym', 'device', 'exercise', 'user');

      verify(() => source.deleteExercise('gym', 'device', 'exercise')).called(1);
    });
  });
}
