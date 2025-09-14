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
      weight: (json['weight'] as num?)?.toDouble(),
      reps: (json['reps'] as num?)?.toInt(),
      dropWeightKg: (json['dropWeightKg'] as num?)?.toDouble(),
      dropReps: (json['dropReps'] as num?)?.toInt(),
      setNumber: WorkoutLogDto._setNumberFromJson(json['setNumber']),
      isBodyweight: json['isBodyweight'] as bool? ?? false,
      isCardio: json['isCardio'] as bool? ?? false,
      mode: json['mode'] as String?,
      durationSec: (json['durationSec'] as num?)?.toInt(),
      speedKmH: (json['speedKmH'] as num?)?.toDouble(),
      intervals:
          WorkoutLogDto._intervalsFromJson(json['intervals'] as List?),
    );

Map<String, dynamic> _$WorkoutLogDtoToJson(WorkoutLogDto instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'sessionId': instance.sessionId,
      if (instance.exerciseId != null) 'exerciseId': instance.exerciseId,
      'timestamp': WorkoutLogDto._dateToTimestamp(instance.timestamp),
      if (instance.weight != null) 'weight': instance.weight,
      if (instance.reps != null) 'reps': instance.reps,
      if (instance.dropWeightKg != null) 'dropWeightKg': instance.dropWeightKg,
      if (instance.dropReps != null) 'dropReps': instance.dropReps,
      'setNumber': instance.setNumber,
      if (instance.isBodyweight) 'isBodyweight': true,
      if (instance.isCardio) 'isCardio': true,
      if (instance.mode != null) 'mode': instance.mode,
      if (instance.durationSec != null) 'durationSec': instance.durationSec,
      if (instance.speedKmH != null) 'speedKmH': instance.speedKmH,
      if (instance.intervals != null)
        'intervals': WorkoutLogDto._intervalsToJson(instance.intervals),
    };
