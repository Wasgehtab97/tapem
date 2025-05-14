// lib/data/dtos/training_plan_dto.dart

import 'package:json_annotation/json_annotation.dart';
import 'exercise_entry_dto.dart';

part 'training_plan_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class TrainingPlanDto {
  final String id;
  final String name;
  final List<ExerciseEntryDto> exercises;

  TrainingPlanDto({
    required this.id,
    required this.name,
    required this.exercises,
  });

  factory TrainingPlanDto.fromJson(Map<String, dynamic> json) =>
      _$TrainingPlanDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TrainingPlanDtoToJson(this);
}
