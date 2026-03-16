import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/training_plan/application/training_plan_provider.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_exercise.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_schedule.dart';
import 'package:tapem/features/training_plan/domain/repositories/training_plan_repository.dart';

enum CreateTrainingPlanFromDayErrorCode {
  invalidPlanName,
  missingUserContext,
  missingGymContext,
  noExercisesFound,
}

class CreateTrainingPlanFromDayException implements Exception {
  const CreateTrainingPlanFromDayException(this.code, this.message);

  final CreateTrainingPlanFromDayErrorCode code;
  final String message;

  @override
  String toString() => 'CreateTrainingPlanFromDayException($code, $message)';
}

class CreateTrainingPlanFromDayResult {
  const CreateTrainingPlanFromDayResult({
    required this.plan,
    required this.duplicatesRemoved,
    required this.invalidSessionsSkipped,
  });

  final TrainingPlan plan;
  final int duplicatesRemoved;
  final int invalidSessionsSkipped;
}

final createTrainingPlanFromDayUseCaseProvider =
    Provider<CreateTrainingPlanFromDayUseCase>((ref) {
      final repository = ref.watch(trainingPlanRepositoryProvider);
      return CreateTrainingPlanFromDayUseCase(repository: repository);
    });

class CreateTrainingPlanFromDayUseCase {
  CreateTrainingPlanFromDayUseCase({required TrainingPlanRepository repository})
    : _repository = repository;

  final TrainingPlanRepository _repository;
  static const _maxNameLength = 60;

  Future<CreateTrainingPlanFromDayResult> execute({
    required String userId,
    required String gymId,
    required String planName,
    required List<Session> sessions,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedGymId = gymId.trim();
    final normalizedName = planName.trim();

    if (normalizedUserId.isEmpty) {
      throw const CreateTrainingPlanFromDayException(
        CreateTrainingPlanFromDayErrorCode.missingUserContext,
        'Missing userId',
      );
    }
    if (normalizedGymId.isEmpty) {
      throw const CreateTrainingPlanFromDayException(
        CreateTrainingPlanFromDayErrorCode.missingGymContext,
        'Missing gymId',
      );
    }
    if (normalizedName.isEmpty || normalizedName.length > _maxNameLength) {
      throw const CreateTrainingPlanFromDayException(
        CreateTrainingPlanFromDayErrorCode.invalidPlanName,
        'Plan name is empty or too long',
      );
    }

    final seenKeys = <String>{};
    final exercises = <TrainingPlanExercise>[];
    var duplicatesRemoved = 0;
    var invalidSessionsSkipped = 0;

    for (final session in sessions) {
      final deviceId = session.deviceId.trim();
      final rawExerciseId = session.exerciseId?.trim() ?? '';
      final exerciseId = rawExerciseId.isNotEmpty ? rawExerciseId : deviceId;

      if (deviceId.isEmpty || exerciseId.isEmpty) {
        invalidSessionsSkipped++;
        continue;
      }

      final dedupeKey = '$deviceId::$exerciseId';
      if (!seenKeys.add(dedupeKey)) {
        duplicatesRemoved++;
        continue;
      }

      final name = _resolveExerciseName(session);
      exercises.add(
        TrainingPlanExercise(
          deviceId: deviceId,
          exerciseId: exerciseId,
          orderIndex: exercises.length,
          name: name,
        ),
      );
    }

    if (exercises.isEmpty) {
      throw const CreateTrainingPlanFromDayException(
        CreateTrainingPlanFromDayErrorCode.noExercisesFound,
        'No valid exercises found for plan creation',
      );
    }

    final now = DateTime.now();
    final plan = TrainingPlan(
      id: const Uuid().v4(),
      name: normalizedName,
      gymId: normalizedGymId,
      exercises: exercises,
      createdAt: now,
      updatedAt: now,
      colorIndex: 0,
      schedule: const TrainingPlanSchedule.disabled(),
      defaultSetCount: null,
    );

    await _repository.savePlan(userId: normalizedUserId, plan: plan);

    return CreateTrainingPlanFromDayResult(
      plan: plan,
      duplicatesRemoved: duplicatesRemoved,
      invalidSessionsSkipped: invalidSessionsSkipped,
    );
  }

  String? _resolveExerciseName(Session session) {
    final exerciseName = session.exerciseName?.trim();
    if (exerciseName != null && exerciseName.isNotEmpty) {
      return exerciseName;
    }
    final deviceName = session.deviceName.trim();
    if (deviceName.isNotEmpty) {
      return deviceName;
    }
    return null;
  }
}
