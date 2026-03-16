import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/profile/application/training_start_plan_resolution_resolver.dart';
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

  test('manual assignment has priority over schedule matches', () {
    final assigned = buildPlan(
      id: 'assigned',
      updatedAt: DateTime(2026, 3, 1),
      schedule: const TrainingPlanSchedule(
        enabled: true,
        mode: TrainingPlanScheduleMode.weekly,
        weekdays: <int>[5],
      ),
    );
    final scheduleMatch = buildPlan(
      id: 'schedule',
      updatedAt: DateTime(2026, 3, 10),
      schedule: const TrainingPlanSchedule(
        enabled: true,
        mode: TrainingPlanScheduleMode.weekly,
        weekdays: <int>[1],
      ),
    );

    final resolved = TrainingStartPlanResolutionResolver.resolve(
      availablePlans: <TrainingPlan>[assigned, scheduleMatch],
      date: DateTime(2026, 3, 9), // Monday
      assignmentPlanId: assigned.id,
    );

    expect(resolved.reason, TrainingStartPlanResolutionReason.manualAssignment);
    expect(resolved.plannedPlan?.id, assigned.id);
    expect(resolved.candidatePlans, isEmpty);
  });

  test('falls back to single schedule match when assignment is missing', () {
    final scheduleMatch = buildPlan(
      id: 'schedule',
      updatedAt: DateTime(2026, 3, 10),
      schedule: const TrainingPlanSchedule(
        enabled: true,
        mode: TrainingPlanScheduleMode.weekly,
        weekdays: <int>[1],
      ),
    );

    final resolved = TrainingStartPlanResolutionResolver.resolve(
      availablePlans: <TrainingPlan>[scheduleMatch],
      date: DateTime(2026, 3, 9), // Monday
      assignmentPlanId: 'missing-plan-id',
    );

    expect(
      resolved.reason,
      TrainingStartPlanResolutionReason.scheduleSingleMatch,
    );
    expect(resolved.plannedPlan?.id, scheduleMatch.id);
    expect(resolved.candidatePlans, isEmpty);
  });

  test('returns multiple schedule candidates sorted by recency', () {
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
      updatedAt: DateTime(2026, 3, 8),
      schedule: const TrainingPlanSchedule(
        enabled: true,
        mode: TrainingPlanScheduleMode.weekly,
        weekdays: <int>[2],
      ),
    );

    final resolved = TrainingStartPlanResolutionResolver.resolve(
      availablePlans: <TrainingPlan>[older, newer],
      date: DateTime(2026, 3, 10), // Tuesday
    );

    expect(
      resolved.reason,
      TrainingStartPlanResolutionReason.scheduleMultipleMatches,
    );
    expect(resolved.plannedPlan, isNull);
    expect(resolved.candidatePlans.map((plan) => plan.id).toList(), <String>[
      'newer',
      'older',
    ]);
  });

  test(
    'returns noResolvedPlan when there is no assignment or schedule match',
    () {
      final unmatched = buildPlan(
        id: 'unmatched',
        updatedAt: DateTime(2026, 3, 8),
        schedule: const TrainingPlanSchedule(
          enabled: true,
          mode: TrainingPlanScheduleMode.weekly,
          weekdays: <int>[5],
        ),
      );

      final resolved = TrainingStartPlanResolutionResolver.resolve(
        availablePlans: <TrainingPlan>[unmatched],
        date: DateTime(2026, 3, 9), // Monday
      );

      expect(resolved.reason, TrainingStartPlanResolutionReason.noResolvedPlan);
      expect(resolved.plannedPlan, isNull);
      expect(resolved.candidatePlans, isEmpty);
    },
  );
}
