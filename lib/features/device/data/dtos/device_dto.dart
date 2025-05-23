// lib/features/device/data/dtos/device_dto.dart
import 'package:json_annotation/json_annotation.dart';
part 'device_dto.g.dart';

@JsonSerializable()
class DeviceDto {
  final String id;
  final String name;
  @JsonKey(defaultValue: '')
  final String description;
  final String? nfcCode;
  @JsonKey(defaultValue: false)
  final bool isMulti;

  DeviceDto({
    required this.id,
    required this.name,
    this.description = '',
    this.nfcCode,
    this.isMulti = false,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceDtoToJson(this);
}
