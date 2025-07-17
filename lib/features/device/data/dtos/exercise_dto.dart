// lib/features/device/data/dtos/exercise_dto.dart
import 'package:json_annotation/json_annotation.dart';
part 'exercise_dto.g.dart';

@JsonSerializable()
class ExerciseDto {
  final String id;
  final String name;
  final String userId;
  final List<String> muscleGroupIds;

  ExerciseDto({
    required this.id,
    required this.name,
    required this.userId,
    List<String>? muscleGroupIds,
  }) : muscleGroupIds = List.from(muscleGroupIds ?? []);

  factory ExerciseDto.fromJson(Map<String, dynamic> json) =>
      _$ExerciseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseDtoToJson(this);
}
