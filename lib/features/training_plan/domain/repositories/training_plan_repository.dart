import '../models/training_plan.dart';

abstract class TrainingPlanRepository {
  Future<List<TrainingPlan>> getPlans(String gymId);
  Future<void> savePlan(String gymId, TrainingPlan plan);
}
