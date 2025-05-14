// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_entry_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExerciseEntryDto _$ExerciseEntryDtoFromJson(Map<String, dynamic> json) =>
    ExerciseEntryDto(
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String,
      sets: (json['sets'] as num).toInt(),
      weight: (json['weight'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
    );

Map<String, dynamic> _$ExerciseEntryDtoToJson(ExerciseEntryDto instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'device_name': instance.deviceName,
      'sets': instance.sets,
      'weight': instance.weight,
      'reps': instance.reps,
    };
