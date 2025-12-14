import 'package:tapem/features/training_plan/data/sources/firestore_training_schedule_source.dart';
import 'package:tapem/features/training_plan/domain/models/training_day_assignment.dart';
import 'package:tapem/features/training_plan/domain/repositories/training_schedule_repository.dart';

class TrainingScheduleRepositoryImpl implements TrainingScheduleRepository {
  TrainingScheduleRepositoryImpl(this._source);

  final FirestoreTrainingScheduleSource _source;

  @override
  Future<TrainingDayAssignment?> getAssignment({
    required String userId,
    required String dateKey,
  }) {
    return _source.getAssignment(userId: userId, dateKey: dateKey);
  }

  @override
  Future<void> setAssignment({
    required String userId,
    required String dateKey,
    required String planId,
  }) {
    return _source.setAssignment(
      userId: userId,
      dateKey: dateKey,
      planId: planId,
    );
  }

  @override
  Future<void> clearAssignment({
    required String userId,
    required String dateKey,
  }) {
    return _source.clearAssignment(userId: userId, dateKey: dateKey);
  }

  @override
  Future<List<TrainingDayAssignment>> getAssignmentsForYear({
    required String userId,
    required int year,
  }) {
    return _source.getAssignmentsForYear(userId: userId, year: year);
  }
}
