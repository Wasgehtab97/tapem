// lib/data/dtos/exercise_entry_dto.dart

import 'package:json_annotation/json_annotation.dart';

part 'exercise_entry_dto.g.dart';

@JsonSerializable()
class ExerciseEntryDto {
  @JsonKey(name: 'device_id')
  final String deviceId;

  @JsonKey(name: 'device_name')
  final String deviceName;

  final int sets;
  final double weight;
  final int reps;

  ExerciseEntryDto({
    required this.deviceId,
    required this.deviceName,
    required this.sets,
    required this.weight,
    required this.reps,
  });

  factory ExerciseEntryDto.fromJson(Map<String, dynamic> json) =>
      _$ExerciseEntryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseEntryDtoToJson(this);
}
