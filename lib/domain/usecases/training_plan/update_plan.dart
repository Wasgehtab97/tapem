// lib/domain/usecases/training_plan/update_plan.dart

import 'package:tapem/domain/repositories/training_plan_repository.dart';
import 'package:tapem/domain/models/training_plan_model.dart';

/// Use-Case: Aktualisiert einen bestehenden Trainingsplan.
///
/// - [plan]: Das vollständige [TrainingPlanModel] mit Änderungen.
class UpdatePlanUseCase {
  final TrainingPlanRepository _repository;

  UpdatePlanUseCase(this._repository);

  Future<void> call({
    required TrainingPlanModel plan,
  }) async {
    await _repository.updatePlan(plan);
  }
}
