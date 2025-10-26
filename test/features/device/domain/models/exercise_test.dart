import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';

void main() {
  group('Exercise', () {
    test('toJson serializes basic fields', () {
      final exercise = Exercise(
        id: 'e1',
        name: 'Bench Press',
        userId: 'u1',
        primaryMuscleGroupIds: const ['chest'],
        secondaryMuscleGroupIds: const ['triceps'],
      );

      expect(exercise.toJson(), {
        'name': 'Bench Press',
        'userId': 'u1',
        'primaryMuscleGroupIds': const ['chest'],
        'secondaryMuscleGroupIds': const ['triceps'],
      });
    });

    test('fromJson fills primary groups when only legacy ids exist', () {
      final json = {
        'id': 'legacy',
        'name': 'Lat Pull',
        'userId': 'user42',
        'muscleGroupIds': const ['back', 'biceps'],
      };

      final exercise = Exercise.fromJson(json);

      expect(exercise.id, 'legacy');
      expect(exercise.primaryMuscleGroupIds, ['back', 'biceps']);
      expect(exercise.secondaryMuscleGroupIds, isEmpty);
      expect(exercise.muscleGroupIds, ['back', 'biceps']);
    });

    test('copyWith updates provided values only', () {
      final exercise = Exercise(
        id: 'base',
        name: 'Curl',
        userId: 'user1',
        primaryMuscleGroupIds: const ['biceps'],
      );

      final updated = exercise.copyWith(
        name: 'Hammer Curl',
        secondaryMuscleGroupIds: const ['forearms'],
      );

      expect(updated.id, 'base');
      expect(updated.name, 'Hammer Curl');
      expect(updated.userId, 'user1');
      expect(updated.primaryMuscleGroupIds, ['biceps']);
      expect(updated.secondaryMuscleGroupIds, ['forearms']);
      expect(updated.muscleGroupIds, ['biceps', 'forearms']);
    });
  });
}
