import 'package:json_annotation/json_annotation.dart';
part 'device_dto.g.dart';

@JsonSerializable()
class DeviceDto {
  final String id;
  final String name;

  @JsonKey(defaultValue: '')
  final String description;

  @JsonKey(name: 'nfcCode') // optionales Feld im Firestore-Dokument
  final String? nfcCode;

  DeviceDto({
    required this.id,
    required this.name,
    this.description = '',
    this.nfcCode,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceDtoToJson(this);
}
