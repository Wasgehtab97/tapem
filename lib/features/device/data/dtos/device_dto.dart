// lib/features/device/data/dtos/device_dto.dart
import 'package:json_annotation/json_annotation.dart';
part 'device_dto.g.dart';

@JsonSerializable()
class DeviceDto {
  final String id;
  final String name;
  @JsonKey(defaultValue: '')
  final String description;

  DeviceDto({
    required this.id,
    required this.name,
    this.description = '',
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceDtoToJson(this);
}
