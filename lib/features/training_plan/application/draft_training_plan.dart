import 'package:equatable/equatable.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_exercise.dart';

class DraftTrainingPlan extends Equatable {
  final String? originalId;
  final String name;
  final List<TrainingPlanExercise> exercises;
  final bool isDirty;

  const DraftTrainingPlan({
    this.originalId,
    this.name = '',
    this.exercises = const [],
    this.isDirty = false,
  });

  DraftTrainingPlan copyWith({
    String? originalId,
    String? name,
    List<TrainingPlanExercise>? exercises,
    bool? isDirty,
  }) {
    return DraftTrainingPlan(
      originalId: originalId ?? this.originalId,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  List<Object?> get props => [originalId, name, exercises, isDirty];
}
