// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_plan_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrainingPlanDto _$TrainingPlanDtoFromJson(Map<String, dynamic> json) =>
    TrainingPlanDto(
      id: json['id'] as String,
      name: json['name'] as String,
      exercises:
          (json['exercises'] as List<dynamic>)
              .map((e) => ExerciseEntryDto.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$TrainingPlanDtoToJson(TrainingPlanDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'exercises': instance.exercises.map((e) => e.toJson()).toList(),
    };
