import '../../domain/models/training_plan.dart';
import '../../domain/repositories/training_plan_repository.dart';
import '../dtos/training_plan_dto.dart';
import '../sources/firestore_training_plan_source.dart';

class TrainingPlanRepositoryImpl implements TrainingPlanRepository {
  final FirestoreTrainingPlanSource _source;

  TrainingPlanRepositoryImpl(this._source);

  @override
  Future<List<TrainingPlan>> getPlans(String gymId, String userId) async {
    final dtos = await _source.getPlans(gymId, userId);
    return dtos.map((d) => d.toModel()).toList();
  }

  @override
  Future<void> savePlan(String gymId, TrainingPlan plan) async {
    final dto = TrainingPlanDto.fromModel(plan);
    await _source.savePlan(gymId, dto);
  }
}
