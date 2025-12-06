import 'package:equatable/equatable.dart';
import 'training_plan_exercise.dart';

class TrainingPlan extends Equatable {
  final String id;
  final String name;
  final String gymId;
  final List<TrainingPlanExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TrainingPlan({
    required this.id,
    required this.name,
    required this.gymId,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
  });

  TrainingPlan copyWith({
    String? id,
    String? name,
    String? gymId,
    List<TrainingPlanExercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainingPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      gymId: gymId ?? this.gymId,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TrainingPlan.fromJson(Map<String, dynamic> json) {
    return TrainingPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      gymId: json['gymId'] as String,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => TrainingPlanExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gymId': gymId,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, gymId, exercises, createdAt, updatedAt];
}
