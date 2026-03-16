import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_exercise.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_schedule.dart';

void main() {
  test('serializes and deserializes TrainingPlan with schedule', () {
    final plan = TrainingPlan(
      id: 'plan-1',
      name: 'Push',
      gymId: 'gym-1',
      exercises: const <TrainingPlanExercise>[
        TrainingPlanExercise(
          deviceId: 'device-1',
          exerciseId: 'exercise-1',
          orderIndex: 0,
          name: 'Bench Press',
        ),
      ],
      createdAt: DateTime(2026, 3, 1, 8, 0),
      updatedAt: DateTime(2026, 3, 2, 9, 0),
      colorIndex: 3,
      defaultSetCount: 5,
      schedule: TrainingPlanSchedule(
        enabled: true,
        mode: TrainingPlanScheduleMode.everyXDays,
        intervalDays: 3,
        anchorDate: DateTime(2026, 3, 1),
      ),
    );

    final json = plan.toJson();
    final decoded = TrainingPlan.fromJson(json);

    expect(decoded.id, plan.id);
    expect(decoded.name, plan.name);
    expect(decoded.schedule, isNotNull);
    expect(decoded.schedule!.enabled, isTrue);
    expect(decoded.schedule!.mode, TrainingPlanScheduleMode.everyXDays);
    expect(decoded.schedule!.intervalDays, 3);
    expect(decoded.schedule!.anchorDate, DateTime(2026, 3, 1));
    expect(decoded.defaultSetCount, 5);
    expect(decoded.resolvedDefaultSetCount, 5);
  });

  test(
    'deserializes TrainingPlan without schedule for backward compatibility',
    () {
      final json = <String, dynamic>{
        'id': 'plan-legacy',
        'name': 'Legacy',
        'gymId': 'gym-1',
        'exercises': <Map<String, dynamic>>[
          <String, dynamic>{
            'deviceId': 'device-1',
            'exerciseId': 'exercise-1',
            'orderIndex': 0,
          },
        ],
        'createdAt': DateTime(2026, 3, 1).toIso8601String(),
        'updatedAt': DateTime(2026, 3, 2).toIso8601String(),
        'colorIndex': 0,
      };

      final decoded = TrainingPlan.fromJson(json);

      expect(decoded.id, 'plan-legacy');
      expect(decoded.schedule, isNull);
      expect(decoded.exercises.length, 1);
      expect(
        decoded.resolvedDefaultSetCount,
        TrainingPlan.fallbackDefaultSetCount,
      );
    },
  );

  test('deserializes schedule when map is dynamic map type', () {
    final json = <String, dynamic>{
      'id': 'plan-dynamic-map',
      'name': 'Dynamic',
      'gymId': 'gym-1',
      'exercises': <Map<String, dynamic>>[
        <String, dynamic>{
          'deviceId': 'device-1',
          'exerciseId': 'exercise-1',
          'orderIndex': 0,
        },
      ],
      'createdAt': DateTime(2026, 3, 1).toIso8601String(),
      'updatedAt': DateTime(2026, 3, 2).toIso8601String(),
      'schedule': <Object?, Object?>{
        'enabled': true,
        'mode': 'weekly',
        'weekdays': <int>[1, 3],
        'intervalDays': 2,
      },
    };

    final decoded = TrainingPlan.fromJson(json);

    expect(decoded.schedule, isNotNull);
    expect(decoded.schedule!.enabled, isTrue);
    expect(decoded.schedule!.mode, TrainingPlanScheduleMode.weekly);
    expect(decoded.schedule!.weekdays, <int>[1, 3]);
  });

  test('defaultSetCount clamps invalid values to fallback', () {
    final json = <String, dynamic>{
      'id': 'plan-invalid-default',
      'name': 'Invalid',
      'gymId': 'gym-1',
      'exercises': <Map<String, dynamic>>[
        <String, dynamic>{
          'deviceId': 'device-1',
          'exerciseId': 'exercise-1',
          'orderIndex': 0,
        },
      ],
      'createdAt': DateTime(2026, 3, 1).toIso8601String(),
      'updatedAt': DateTime(2026, 3, 2).toIso8601String(),
      'defaultSetCount': 0,
    };

    final decoded = TrainingPlan.fromJson(json);
    expect(decoded.defaultSetCount, TrainingPlan.fallbackDefaultSetCount);
    expect(
      decoded.resolvedDefaultSetCount,
      TrainingPlan.fallbackDefaultSetCount,
    );
  });
}
