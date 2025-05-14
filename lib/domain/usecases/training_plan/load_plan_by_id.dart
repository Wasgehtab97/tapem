// lib/domain/usecases/training_plan/load_plan_by_id.dart

import 'package:tapem/domain/repositories/training_plan_repository.dart';
import 'package:tapem/domain/models/training_plan_model.dart';

/// Use-Case: Holt einen einzelnen Trainingsplan.
///
/// - [userId]: ID des Nutzers.
/// - [planId]: ID des gewünschten Plans.
///
/// Liefert das entsprechende [TrainingPlanModel].
class LoadPlanByIdUseCase {
  final TrainingPlanRepository _repository;

  LoadPlanByIdUseCase(this._repository);

  Future<TrainingPlanModel> call({
    required String userId,
    required String planId,
  }) async {
    return await _repository.loadPlanById(userId, planId);
  }
}
