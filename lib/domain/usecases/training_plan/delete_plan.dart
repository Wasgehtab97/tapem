// lib/domain/usecases/training_plan/delete_plan.dart

import 'package:tapem/domain/repositories/training_plan_repository.dart';

/// Use-Case: Löscht einen bestehenden Trainingsplan.
///
/// - [userId]: ID des Nutzers, dem der Plan gehört.
/// - [planId]: ID des zu löschenden Plans.
class DeletePlanUseCase {
  final TrainingPlanRepository _repository;

  DeletePlanUseCase(this._repository);

  Future<void> call({
    required String userId,
    required String planId,
  }) async {
    await _repository.deletePlan(userId, planId);
  }
}
