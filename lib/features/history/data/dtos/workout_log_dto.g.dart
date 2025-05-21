// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_log_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutLogDto _$WorkoutLogDtoFromJson(Map<String, dynamic> json) =>
    WorkoutLogDto(
      userId: json['userId'] as String,
      sessionId: json['sessionId'] as String,
      timestamp: WorkoutLogDto._timestampToDate(json['timestamp'] as Timestamp),
      weight: (json['weight'] as num).toInt(),
      reps: (json['reps'] as num).toInt(),
    );

Map<String, dynamic> _$WorkoutLogDtoToJson(WorkoutLogDto instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'sessionId': instance.sessionId,
      'timestamp': WorkoutLogDto._dateToTimestamp(instance.timestamp),
      'weight': instance.weight,
      'reps': instance.reps,
    };
