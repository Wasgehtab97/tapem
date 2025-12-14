import 'package:equatable/equatable.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan_exercise.dart';

class DraftTrainingPlan extends Equatable {
  final String? originalId;
  final String name;
  final List<TrainingPlanExercise> exercises;
  final bool isDirty;
   /// Wenn gesetzt, wird der Plan für diesen Nutzer gespeichert (z.B. Client),
   /// ansonsten für den aktuell eingeloggten User.
  final String? targetUserId;
  final String? coachId;
  final String? coachingRelationId;
  final int colorIndex;

  const DraftTrainingPlan({
    this.originalId,
    this.name = '',
    this.exercises = const [],
    this.isDirty = false,
    this.targetUserId,
    this.coachId,
    this.coachingRelationId,
    this.colorIndex = 0,
  });

  DraftTrainingPlan copyWith({
    String? originalId,
    String? name,
    List<TrainingPlanExercise>? exercises,
    bool? isDirty,
    String? targetUserId,
    String? coachId,
    String? coachingRelationId,
    int? colorIndex,
  }) {
    return DraftTrainingPlan(
      originalId: originalId ?? this.originalId,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      isDirty: isDirty ?? this.isDirty,
      targetUserId: targetUserId ?? this.targetUserId,
      coachId: coachId ?? this.coachId,
      coachingRelationId: coachingRelationId ?? this.coachingRelationId,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  @override
  List<Object?> get props =>
      [originalId, name, exercises, isDirty, targetUserId, coachId, coachingRelationId, colorIndex];
}
