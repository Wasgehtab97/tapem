import 'package:equatable/equatable.dart';
import '../../../domain/models/training_plan_model.dart';

abstract class TrainingPlanEvent extends Equatable {
  const TrainingPlanEvent();
  @override
  List<Object?> get props => [];
}

/// Lädt alle Pläne für einen Nutzer.
class TrainingPlanLoadAll extends TrainingPlanEvent {
  final String userId;
  const TrainingPlanLoadAll(this.userId);
  @override
  List<Object?> get props => [userId];
}

/// Lädt einen einzelnen Plan per ID.
class TrainingPlanLoadById extends TrainingPlanEvent {
  final String userId;
  final String planId;
  const TrainingPlanLoadById({
    required this.userId,
    required this.planId,
  });
  @override
  List<Object?> get props => [userId, planId];
}

/// Erstellt einen neuen Plan.
class TrainingPlanCreate extends TrainingPlanEvent {
  final String userId;
  final String name;
  const TrainingPlanCreate({
    required this.userId,
    required this.name,
  });
  @override
  List<Object?> get props => [userId, name];
}

/// Aktualisiert einen bestehenden Plan.
class TrainingPlanUpdate extends TrainingPlanEvent {
  final String userId;
  final TrainingPlanModel plan;
  const TrainingPlanUpdate({
    required this.userId,
    required this.plan,
  });
  @override
  List<Object?> get props => [userId, plan];
}

/// Löscht einen Plan.
class TrainingPlanDelete extends TrainingPlanEvent {
  final String userId;
  final String planId;
  const TrainingPlanDelete({
    required this.userId,
    required this.planId,
  });
  @override
  List<Object?> get props => [userId, planId];
}

/// Startet einen Plan.
class TrainingPlanStart extends TrainingPlanEvent {
  final String userId;
  final String planId;
  const TrainingPlanStart({
    required this.userId,
    required this.planId,
  });
  @override
  List<Object?> get props => [userId, planId];
}
