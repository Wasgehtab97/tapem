import 'package:equatable/equatable.dart';
import '../../../domain/models/training_plan_model.dart';

abstract class TrainingPlanState extends Equatable {
  const TrainingPlanState();
  @override
  List<Object?> get props => [];
}

class TrainingPlanInitial extends TrainingPlanState {}

class TrainingPlanLoading extends TrainingPlanState {}

class TrainingPlanLoadSuccess extends TrainingPlanState {
  final List<TrainingPlanModel> plans;
  const TrainingPlanLoadSuccess(this.plans);
  @override
  List<Object?> get props => [plans];
}

class TrainingPlanSelected extends TrainingPlanState {
  final TrainingPlanModel plan;
  const TrainingPlanSelected(this.plan);
  @override
  List<Object?> get props => [plan];
}

class TrainingPlanCreateSuccess extends TrainingPlanState {
  final String planId;
  const TrainingPlanCreateSuccess(this.planId);
  @override
  List<Object?> get props => [planId];
}

class TrainingPlanUpdateSuccess extends TrainingPlanState {
  const TrainingPlanUpdateSuccess();
}

class TrainingPlanDeleteSuccess extends TrainingPlanState {
  const TrainingPlanDeleteSuccess();
}

class TrainingPlanStartSuccess extends TrainingPlanState {
  const TrainingPlanStartSuccess();
}

class TrainingPlanFailure extends TrainingPlanState {
  final String error;
  const TrainingPlanFailure(this.error);
  @override
  List<Object?> get props => [error];
}
