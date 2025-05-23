// lib/features/device/data/dtos/exercise_dto.dart
import 'package:json_annotation/json_annotation.dart';
part 'exercise_dto.g.dart';

@JsonSerializable()
class ExerciseDto {
  final String id;
  final String name;
  final String userId;

  ExerciseDto({
    required this.id,
    required this.name,
    required this.userId,
  });

  factory ExerciseDto.fromJson(Map<String, dynamic> json) =>
      _$ExerciseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseDtoToJson(this);
}
