// lib/domain/models/training_plan_model.dart

import 'exercise_entry.dart';

/// Ein Trainingsplan mit einer Liste von [ExerciseEntry]-Sätzen.
class TrainingPlanModel {
  /// Plan-ID (Firestore-Dokument)
  final String id;

  /// Plan-Name
  final String name;

  /// Alle enthaltenen Übungseinheiten
  final List<ExerciseEntry> exercises;

  const TrainingPlanModel({
    required this.id,
    required this.name,
    required this.exercises,
  });

  /// Aus Firestore-Daten. **Unbedingt** das `id:` mitgeben!
  factory TrainingPlanModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    final raw = map['exercises'] as List<dynamic>? ?? <dynamic>[];
    return TrainingPlanModel(
      id: id,
      name: map['name'] as String? ?? '',
      exercises: raw
          .map((e) => ExerciseEntry.fromMap(
                e as Map<String, dynamic>,
                id: (e as Map<String, dynamic>)['id'] as String? ?? '',
              ))
          .toList(),
    );
  }

  /// Zurück in Map (für Firestore-Writes)
  Map<String, dynamic> toMap() => {
        'name': name,
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };

  @override
  String toString() =>
      'TrainingPlanModel(id: $id, name: $name, exercises: ${exercises.length})';
}
