import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/domain/repositories/training_plan_repository.dart';
import 'package:tapem/features/training_plan/data/sources/firestore_training_plan_source.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_stats.dart';

class TrainingPlanRepositoryImpl implements TrainingPlanRepository {
  final FirestoreTrainingPlanSource _source;

  TrainingPlanRepositoryImpl(this._source);

  @override
  Future<List<TrainingPlan>> getPlans({
    required String gymId,
    required String userId,
  }) {
    return _source.getPlans(gymId: gymId, userId: userId);
  }

  @override
  Future<void> savePlan({
    required String userId,
    required TrainingPlan plan,
  }) {
    return _source.savePlan(userId: userId, plan: plan);
  }

  @override
  Future<void> deletePlan({
    required String userId,
    required String planId,
  }) {
    return _source.deletePlan(userId: userId, planId: planId);
  }

  @override
  Future<TrainingPlanStats> getStats({
    required String userId,
    required String planId,
  }) {
    return _source.getStats(userId: userId, planId: planId);
  }

  @override
  Future<void> incrementCompletion({
    required String userId,
    required String planId,
  }) {
    return _source.incrementCompletion(userId: userId, planId: planId);
  }
}
