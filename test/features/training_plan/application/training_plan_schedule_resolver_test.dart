import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/training_plan/application/training_plan_schedule_resolver.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_exercise.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_schedule.dart';

void main() {
  TrainingPlan buildPlan({
    required String id,
    required DateTime updatedAt,
    TrainingPlanSchedule? schedule,
  }) {
    return TrainingPlan(
      id: id,
      name: 'Plan $id',
      gymId: 'gym-1',
      exercises: const <TrainingPlanExercise>[],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: updatedAt,
      schedule: schedule,
    );
  }

  test('weekly schedule matches correct weekday', () {
    final mondayPlan = buildPlan(
      id: 'monday',
      updatedAt: DateTime(2026, 3, 1),
      schedule: const TrainingPlanSchedule(
        enabled: true,
        mode: TrainingPlanScheduleMode.weekly,
        weekdays: <int>[1, 3],
      ),
    );
    final fridayPlan = buildPlan(
      id: 'friday',
      updatedAt: DateTime(2026, 3, 2),
      schedule: const TrainingPlanSchedule(
        enabled: true,
        mode: TrainingPlanScheduleMode.weekly,
        weekdays: <int>[5],
      ),
    );

    final matching = TrainingPlanScheduleResolver.matchingPlansForDate(
      plans: <TrainingPlan>[mondayPlan, fridayPlan],
      date: DateTime(2026, 3, 9), // Monday
    );

    expect(matching.map((plan) => plan.id), <String>['monday']);
  });

  test('every X days schedule matches based on anchor date', () {
    final intervalPlan = buildPlan(
      id: 'interval',
      updatedAt: DateTime(2026, 3, 5),
      schedule: TrainingPlanSchedule(
        enabled: true,
        mode: TrainingPlanScheduleMode.everyXDays,
        intervalDays: 2,
        anchorDate: DateTime(2026, 3, 1),
      ),
    );

    final match = TrainingPlanScheduleResolver.resolvePreferredPlanForDate(
      plans: <TrainingPlan>[intervalPlan],
      date: DateTime(2026, 3, 7),
    );
    final noMatch = TrainingPlanScheduleResolver.resolvePreferredPlanForDate(
      plans: <TrainingPlan>[intervalPlan],
      date: DateTime(2026, 3, 8),
    );

    expect(match?.id, 'interval');
    expect(noMatch, isNull);
  });

  test('every X days schedule matches across month boundary', () {
    final intervalPlan = buildPlan(
      id: 'month-boundary',
      updatedAt: DateTime(2026, 1, 30),
      schedule: TrainingPlanSchedule(
        enabled: true,
        mode: TrainingPlanScheduleMode.everyXDays,
        intervalDays: 2,
        anchorDate: DateTime(2026, 1, 30),
      ),
    );

    final match = TrainingPlanScheduleResolver.resolvePreferredPlanForDate(
      plans: <TrainingPlan>[intervalPlan],
      date: DateTime(2026, 2, 1),
    );
    final noMatch = TrainingPlanScheduleResolver.resolvePreferredPlanForDate(
      plans: <TrainingPlan>[intervalPlan],
      date: DateTime(2026, 2, 2),
    );

    expect(match?.id, 'month-boundary');
    expect(noMatch, isNull);
  });

  test('every X days schedule matches across year boundary', () {
    final intervalPlan = buildPlan(
      id: 'year-boundary',
      updatedAt: DateTime(2025, 12, 31),
      schedule: TrainingPlanSchedule(
        enabled: true,
        mode: TrainingPlanScheduleMode.everyXDays,
        intervalDays: 2,
        anchorDate: DateTime(2025, 12, 31),
      ),
    );

    final match = TrainingPlanScheduleResolver.resolvePreferredPlanForDate(
      plans: <TrainingPlan>[intervalPlan],
      date: DateTime(2026, 1, 2),
    );
    final noMatch = TrainingPlanScheduleResolver.resolvePreferredPlanForDate(
      plans: <TrainingPlan>[intervalPlan],
      date: DateTime(2026, 1, 1),
    );

    expect(match?.id, 'year-boundary');
    expect(noMatch, isNull);
  });

  test('resolver prefers most recently updated plan when multiple match', () {
    final older = buildPlan(
      id: 'older',
      updatedAt: DateTime(2026, 3, 1),
      schedule: const TrainingPlanSchedule(
        enabled: true,
        mode: TrainingPlanScheduleMode.weekly,
        weekdays: <int>[2],
      ),
    );
    final newer = buildPlan(
      id: 'newer',
      updatedAt: DateTime(2026, 3, 10),
      schedule: const TrainingPlanSchedule(
        enabled: true,
        mode: TrainingPlanScheduleMode.weekly,
        weekdays: <int>[2],
      ),
    );

    final selected = TrainingPlanScheduleResolver.resolvePreferredPlanForDate(
      plans: <TrainingPlan>[older, newer],
      date: DateTime(2026, 3, 10), // Tuesday
    );

    expect(selected?.id, 'newer');
  });

  test('disabled schedule is ignored', () {
    final disabled = buildPlan(
      id: 'disabled',
      updatedAt: DateTime(2026, 3, 10),
      schedule: const TrainingPlanSchedule(
        enabled: false,
        mode: TrainingPlanScheduleMode.weekly,
        weekdays: <int>[2],
      ),
    );

    final selected = TrainingPlanScheduleResolver.resolvePreferredPlanForDate(
      plans: <TrainingPlan>[disabled],
      date: DateTime(2026, 3, 10),
    );

    expect(selected, isNull);
  });
}
