// lib/domain/usecases/training_plan/create_plan.dart

import 'package:tapem/domain/repositories/training_plan_repository.dart';

/// Use-Case: Erstellt einen neuen Trainingsplan für einen Nutzer.
///
/// - [userId]: ID des Nutzers, dem der Plan gehört.
/// - [name]: Name des neuen Plans.
///
/// Liefert die ID des erstellten Plans als String zurück.
class CreatePlanUseCase {
  final TrainingPlanRepository _repository;

  CreatePlanUseCase(this._repository);

  Future<String> call({
    required String userId,
    required String name,
  }) async {
    return await _repository.createPlan(userId, name);
  }
}
