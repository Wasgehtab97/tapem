// lib/domain/usecases/training_plan/start_plan.dart

import 'package:tapem/domain/repositories/training_plan_repository.dart';

/// Use-Case: Startet einen Trainingsplan.
///
/// - [userId]: ID des Nutzers.
/// - [planId]: ID des zu startenden Plans.
class StartPlanUseCase {
  final TrainingPlanRepository _repository;

  StartPlanUseCase(this._repository);

  Future<void> call({
    required String userId,
    required String planId,
  }) async {
    await _repository.startPlan(userId, planId);
  }
}
