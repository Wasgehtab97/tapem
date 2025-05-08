// lib/core/models/dto/device_dto.dart

import 'package:json_annotation/json_annotation.dart';
part 'device_dto.g.dart';

@JsonSerializable()
class DeviceDto {
  /// Numerische Geräte-ID aus Firestore-Feld `id`
  @JsonKey(name: 'id')
  final int deviceId;

  /// Firestore-Dokument-ID
  final String documentId;

  /// Name des Geräts
  final String name;

  /// Modus/Übungstyp
  @JsonKey(name: 'exercise_mode')
  final String exerciseMode;

  /// Geheimcode (wird selten genutzt)
  @JsonKey(name: 'secret_code')
  final String secretCode;

  DeviceDto({
    required this.deviceId,
    required this.documentId,
    required this.name,
    required this.exerciseMode,
    required this.secretCode,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceDtoToJson(this);
}
