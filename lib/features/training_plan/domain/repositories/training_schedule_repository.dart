import 'package:tapem/features/training_plan/domain/models/training_day_assignment.dart';

abstract class TrainingScheduleRepository {
  Future<TrainingDayAssignment?> getAssignment({
    required String userId,
    required String dateKey,
  });

  Future<List<TrainingDayAssignment>> getAssignmentsForYear({
    required String userId,
    required int year,
  });

  Future<void> setAssignment({
    required String userId,
    required String dateKey,
    required String planId,
  });

  Future<void> clearAssignment({
    required String userId,
    required String dateKey,
  });
}
