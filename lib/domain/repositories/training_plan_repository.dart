// lib/domain/repositories/training_plan_repository.dart

import '../models/training_plan_model.dart';

/// Schnittstelle für Trainingsplan-Feature.
abstract class TrainingPlanRepository {
  /// Lädt alle Pläne des Nutzers.
  Future<List<TrainingPlanModel>> loadPlans(String userId);

  /// Erstellt einen neuen Plan und gibt die Plan-ID zurück.
  Future<String> createPlan(String userId, String name);

  /// Löscht den Plan [planId].
  Future<void> deletePlan(String userId, String planId);

  /// Aktualisiert einen bestehenden Plan.
  Future<void> updatePlan(TrainingPlanModel plan);

  /// Lädt den Plan [planId].
  Future<TrainingPlanModel> loadPlanById(String userId, String planId);

  /// Startet einen Plan (z. B. setzt ihn als aktiv).
  Future<void> startPlan(String userId, String planId);
}
