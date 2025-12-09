import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_stats.dart';

abstract class TrainingPlanRepository {
  Future<List<TrainingPlan>> getPlans({
    required String gymId, 
    required String userId,
  });

  Future<void> savePlan({
    required String userId,
    required TrainingPlan plan,
  });

  Future<void> deletePlan({
    required String userId,
    required String planId,
  });

  Future<TrainingPlanStats> getStats({
    required String userId,
    required String planId,
  });

  Future<void> incrementCompletion({
    required String userId,
    required String planId,
  });
}
