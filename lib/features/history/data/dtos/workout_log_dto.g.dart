// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_log_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutLogDto _$WorkoutLogDtoFromJson(Map<String, dynamic> json) =>
    WorkoutLogDto(
      userId: json['userId'] as String,
      sessionId: json['sessionId'] as String,
      exerciseId: json['exerciseId'] as String?,
      timestamp: WorkoutLogDto._timestampToDate(json['timestamp'] as Timestamp),
      weight: (json['weight'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
      dropWeightKg: (json['dropWeightKg'] as num?)?.toDouble(),
      dropReps: (json['dropReps'] as num?)?.toInt(),
      setNumber: WorkoutLogDto._setNumberFromJson(json['setNumber']),
      isBodyweight: json['isBodyweight'] as bool? ?? false,
    );

Map<String, dynamic> _$WorkoutLogDtoToJson(WorkoutLogDto instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'sessionId': instance.sessionId,
      if (instance.exerciseId != null) 'exerciseId': instance.exerciseId,
      'timestamp': WorkoutLogDto._dateToTimestamp(instance.timestamp),
      'weight': instance.weight,
      'reps': instance.reps,
      if (instance.dropWeightKg != null) 'dropWeightKg': instance.dropWeightKg,
      if (instance.dropReps != null) 'dropReps': instance.dropReps,
      'setNumber': instance.setNumber,
      if (instance.isBodyweight) 'isBodyweight': true,
    };
