// lib/data/dtos/gym_config_dto.dart

import 'package:json_annotation/json_annotation.dart';

part 'gym_config_dto.g.dart';

@JsonSerializable()
class GymConfigDto {
  @JsonKey(name: 'gym_id')
  final String gymId;

  /// Der im Tenant angezeigte Name
  final String name;

  @JsonKey(name: 'logo_url')
  final String logoUrl;

  /// Map aus Farb‐Keys -> Hex‐Strings
  @JsonKey(name: 'theme_colors')
  final Map<String, String> themeColors;

  GymConfigDto({
    required this.gymId,
    required this.name,
    required this.logoUrl,
    required this.themeColors,
  });

  factory GymConfigDto.fromJson(Map<String, dynamic> json) =>
      _$GymConfigDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GymConfigDtoToJson(this);
}
