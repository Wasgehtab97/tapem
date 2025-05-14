// lib/data/dtos/device_dto.dart

import 'package:json_annotation/json_annotation.dart';

part 'device_dto.g.dart';

@JsonSerializable()
class DeviceDto {
  final String name;

  @JsonKey(name: 'exercise_mode')
  final String exerciseMode;

  @JsonKey(name: 'secret_code')
  final String secretCode;

  DeviceDto({
    required this.name,
    required this.exerciseMode,
    required this.secretCode,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceDtoToJson(this);
}
