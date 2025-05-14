// lib/domain/usecases/training_plan/load_plans.dart

import 'package:tapem/domain/repositories/training_plan_repository.dart';
import 'package:tapem/domain/models/training_plan_model.dart';

/// Use-Case: Holt alle Trainingspläne eines Nutzers.
///
/// - [userId]: ID des Nutzers.
///
/// Liefert eine Liste von [TrainingPlanModel].
class LoadPlansUseCase {
  final TrainingPlanRepository _repository;

  LoadPlansUseCase(this._repository);

  Future<List<TrainingPlanModel>> call({
    required String userId,
  }) async {
    return await _repository.loadPlans(userId);
  }
}
