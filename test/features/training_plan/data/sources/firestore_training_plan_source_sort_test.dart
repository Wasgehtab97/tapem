import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/training_plan/data/sources/firestore_training_plan_source.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_exercise.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_schedule.dart';

TrainingPlan _plan({
  required String id,
  int? listOrder,
  required DateTime createdAt,
  required DateTime updatedAt,
}) {
  return TrainingPlan(
    id: id,
    name: id,
    gymId: 'gym-1',
    exercises: const <TrainingPlanExercise>[],
    createdAt: createdAt,
    updatedAt: updatedAt,
    listOrder: listOrder,
    colorIndex: 0,
    schedule: const TrainingPlanSchedule.disabled(),
    defaultSetCount: null,
  );
}

void main() {
  test('sorts by persisted listOrder first', () {
    final plans = <TrainingPlan>[
      _plan(
        id: 'b',
        listOrder: 1,
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 1, 10),
      ),
      _plan(
        id: 'a',
        listOrder: 0,
        createdAt: DateTime(2026, 3, 2),
        updatedAt: DateTime(2026, 3, 2, 10),
      ),
    ];

    final sorted = sortTrainingPlansForOverview(plans);

    expect(sorted.map((p) => p.id), <String>['a', 'b']);
  });

  test('falls back to updatedAt desc when listOrder is missing', () {
    final plans = <TrainingPlan>[
      _plan(
        id: 'older',
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 1, 10),
      ),
      _plan(
        id: 'newer',
        createdAt: DateTime(2026, 3, 2),
        updatedAt: DateTime(2026, 3, 2, 10),
      ),
    ];

    final sorted = sortTrainingPlansForOverview(plans);

    expect(sorted.map((p) => p.id), <String>['newer', 'older']);
  });

  test('keeps manually ordered plans before unordered plans', () {
    final plans = <TrainingPlan>[
      _plan(
        id: 'unordered',
        createdAt: DateTime(2026, 3, 3),
        updatedAt: DateTime(2026, 3, 3, 10),
      ),
      _plan(
        id: 'ordered',
        listOrder: 0,
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 1, 10),
      ),
    ];

    final sorted = sortTrainingPlansForOverview(plans);

    expect(sorted.map((p) => p.id), <String>['ordered', 'unordered']);
  });
}
