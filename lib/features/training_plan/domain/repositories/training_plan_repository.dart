import '../models/training_plan.dart';

abstract class TrainingPlanRepository {
  Future<List<TrainingPlan>> getPlans(String gymId, String userId);
  Future<void> savePlan(String gymId, TrainingPlan plan);
  Future<void> renamePlan(
    String gymId,
    String planId,
    String newName,
  );

  Future<void> deletePlan(String gymId, String planId);
}
