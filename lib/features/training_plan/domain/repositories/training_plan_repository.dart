import '../models/training_plan.dart';

abstract class TrainingPlanRepository {
  Future<List<TrainingPlan>> getPlans(String gymId, String userId);
  Future<void> savePlan(String gymId, TrainingPlan plan);
}
