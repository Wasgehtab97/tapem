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
      rir: json['rir'] as int?,
      note: json['setNote'] as String?,
      dropWeightKg: (json['dropWeightKg'] as num?)?.toDouble(),
      dropReps: (json['dropReps'] as num?)?.toInt(),
      dropSets: (json['dropSets'] as List<dynamic>?)
          ?.map((e) => DropSetDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WorkoutLogDtoToJson(WorkoutLogDto instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'sessionId': instance.sessionId,
      if (instance.exerciseId != null) 'exerciseId': instance.exerciseId,
      'timestamp': WorkoutLogDto._dateToTimestamp(instance.timestamp),
      'weight': instance.weight,
      'reps': instance.reps,
      if (instance.rir != null) 'rir': instance.rir,
      if (instance.note != null) 'setNote': instance.note,
      if (instance.dropWeightKg != null) 'dropWeightKg': instance.dropWeightKg,
      if (instance.dropReps != null) 'dropReps': instance.dropReps,
      if (instance.dropSets != null)
        'dropSets': instance.dropSets!.map((e) => e.toJson()).toList(),
    };
