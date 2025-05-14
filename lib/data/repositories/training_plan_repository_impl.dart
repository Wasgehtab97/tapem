import 'package:tapem/domain/repositories/training_plan_repository.dart';
import 'package:tapem/domain/models/training_plan_model.dart';
import 'package:tapem/data/sources/training_plan/firestore_training_plan_source.dart';

class TrainingPlanRepositoryImpl implements TrainingPlanRepository {
  final FirestoreTrainingPlanSource _source;
  TrainingPlanRepositoryImpl(this._source);

  @override
  Future<List<TrainingPlanModel>> loadPlans(String userId) async {
    final snaps = await _source.loadPlans(userId);
    return snaps
        .map((doc) => TrainingPlanModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  @override
  Future<String> createPlan(String userId, String name) =>
      _source.createPlan(userId, name);

  @override
  Future<void> deletePlan(String userId, String planId) =>
      _source.deletePlan(userId, planId);

  @override
  Future<TrainingPlanModel> loadPlanById(String userId, String planId) async {
    final doc = await _source.loadPlanById(userId, planId);
    return TrainingPlanModel.fromMap(doc.data()!, id: doc.id);
  }

  @override
  Future<void> startPlan(String userId, String planId) =>
      _source.startPlan(userId, planId);

  @override
  Future<void> updatePlan(TrainingPlanModel plan) =>
      _source.updatePlan(plan);
}
