import 'package:equatable/equatable.dart';
import 'training_plan_exercise.dart';

class TrainingPlan extends Equatable {
  final String id;
  final String name;
  final String gymId;
  final String? coachId;
  final String? clientId;
  final String? coachingRelationId;
  final List<TrainingPlanExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int colorIndex;

  const TrainingPlan({
    required this.id,
    required this.name,
    required this.gymId,
    this.coachId,
    this.clientId,
    this.coachingRelationId,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
    this.colorIndex = 0,
  });

  TrainingPlan copyWith({
    String? id,
    String? name,
    String? gymId,
    String? coachId,
    String? clientId,
    String? coachingRelationId,
    List<TrainingPlanExercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? colorIndex,
  }) {
    return TrainingPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      gymId: gymId ?? this.gymId,
      coachId: coachId ?? this.coachId,
      clientId: clientId ?? this.clientId,
      coachingRelationId: coachingRelationId ?? this.coachingRelationId,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  factory TrainingPlan.fromJson(Map<String, dynamic> json) {
    return TrainingPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      gymId: json['gymId'] as String,
      coachId: json['coachId'] as String?,
      clientId: json['clientId'] as String?,
      coachingRelationId: json['coachingRelationId'] as String?,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => TrainingPlanExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      colorIndex: (json['colorIndex'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gymId': gymId,
      if (coachId != null) 'coachId': coachId,
      if (clientId != null) 'clientId': clientId,
      if (coachingRelationId != null) 'coachingRelationId': coachingRelationId,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'colorIndex': colorIndex,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        gymId,
        coachId,
        clientId,
        coachingRelationId,
        exercises,
        createdAt,
        updatedAt,
        colorIndex,
      ];
}
