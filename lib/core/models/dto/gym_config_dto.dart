// lib/core/models/dto/gym_config_dto.dart

import 'package:json_annotation/json_annotation.dart';
part 'gym_config_dto.g.dart';

@JsonSerializable()
class GymConfigDto {
  final String gymId;
  final String name;
  final String primaryColorHex;

  GymConfigDto({
    required this.gymId,
    required this.name,
    required this.primaryColorHex,
  });

  factory GymConfigDto.fromJson(Map<String, dynamic> json) =>
      _$GymConfigDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GymConfigDtoToJson(this);
}
