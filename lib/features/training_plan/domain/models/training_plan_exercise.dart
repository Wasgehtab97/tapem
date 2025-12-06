import 'package:equatable/equatable.dart';

class TrainingPlanExercise extends Equatable {
  final String deviceId;
  final String exerciseId;
  final String? name; // Cached name ("Incline Press" or Device Name)
  final String? notes; // For future use
  final int orderIndex; // To maintain order

  const TrainingPlanExercise({
    required this.deviceId,
    required this.exerciseId,
    required this.orderIndex,
    this.name,
    this.notes,
  });

  TrainingPlanExercise copyWith({
    String? deviceId,
    String? exerciseId,
    String? name,
    String? notes,
    int? orderIndex,
  }) {
    return TrainingPlanExercise(
      deviceId: deviceId ?? this.deviceId,
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  factory TrainingPlanExercise.fromJson(Map<String, dynamic> json) {
    return TrainingPlanExercise(
      deviceId: json['deviceId'] as String,
      exerciseId: json['exerciseId'] as String,
      orderIndex: json['orderIndex'] as int,
      name: json['name'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'exerciseId': exerciseId,
      'orderIndex': orderIndex,
      if (name != null) 'name': name,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [deviceId, exerciseId, orderIndex, name, notes];
}
