// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExerciseDto _$ExerciseDtoFromJson(Map<String, dynamic> json) => ExerciseDto(
  id: json['id'] as String,
  name: json['name'] as String,
  userId: json['userId'] as String,
  primaryMuscleGroupIds:
      (json['primaryMuscleGroupIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
  secondaryMuscleGroupIds:
      (json['secondaryMuscleGroupIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
);

Map<String, dynamic> _$ExerciseDtoToJson(ExerciseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'userId': instance.userId,
      'primaryMuscleGroupIds': instance.primaryMuscleGroupIds,
      'secondaryMuscleGroupIds': instance.secondaryMuscleGroupIds,
    };
