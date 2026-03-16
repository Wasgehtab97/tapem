import 'package:equatable/equatable.dart';
import 'training_plan_exercise.dart';
import 'training_plan_schedule.dart';

class TrainingPlan extends Equatable {
  static const int fallbackDefaultSetCount = 3;

  final String id;
  final String name;
  final String gymId;
  final String? coachId;
  final String? clientId;
  final String? coachingRelationId;
  final List<TrainingPlanExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? listOrder;
  final int colorIndex;
  final TrainingPlanSchedule? schedule;
  final int? defaultSetCount;

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
    this.listOrder,
    this.colorIndex = 0,
    this.schedule,
    this.defaultSetCount,
  });

  int get resolvedDefaultSetCount => sanitizeDefaultSetCount(defaultSetCount);

  static int sanitizeDefaultSetCount(int? value) {
    if (value == null || value < 1) {
      return fallbackDefaultSetCount;
    }
    return value;
  }

  static int? _parseDefaultSetCount(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      return int.tryParse(raw.trim());
    }
    return null;
  }

  static int? _parseListOrder(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      return int.tryParse(raw.trim());
    }
    return null;
  }

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
    int? listOrder,
    int? colorIndex,
    TrainingPlanSchedule? schedule,
    int? defaultSetCount,
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
      listOrder: listOrder ?? this.listOrder,
      colorIndex: colorIndex ?? this.colorIndex,
      schedule: schedule ?? this.schedule,
      defaultSetCount: defaultSetCount ?? this.defaultSetCount,
    );
  }

  factory TrainingPlan.fromJson(Map<String, dynamic> json) {
    final parsedDefaultSetCount = _parseDefaultSetCount(
      json['defaultSetCount'],
    );
    final parsedListOrder = _parseListOrder(json['listOrder']);
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
      listOrder: parsedListOrder,
      colorIndex: (json['colorIndex'] as int?) ?? 0,
      schedule: json['schedule'] is Map<String, dynamic>
          ? TrainingPlanSchedule.fromJson(
              json['schedule'] as Map<String, dynamic>,
            )
          : (json['schedule'] is Map
                ? TrainingPlanSchedule.fromJson(
                    Map<String, dynamic>.from(json['schedule'] as Map),
                  )
                : null),
      defaultSetCount: parsedDefaultSetCount == null
          ? null
          : sanitizeDefaultSetCount(parsedDefaultSetCount),
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
      if (listOrder != null) 'listOrder': listOrder,
      'colorIndex': colorIndex,
      if (schedule != null) 'schedule': schedule!.toJson(),
      if (defaultSetCount != null)
        'defaultSetCount': sanitizeDefaultSetCount(defaultSetCount),
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
    listOrder,
    colorIndex,
    schedule,
    defaultSetCount,
  ];
}
