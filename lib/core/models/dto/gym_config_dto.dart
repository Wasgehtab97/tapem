// lib/core/models/dto/gym_config_dto.dart

import 'package:json_annotation/json_annotation.dart';
part 'gym_config_dto.g.dart';

/// Data Transfer Object für GymConfig in Firestore.
/// Erwartete Firestore-Felder:
/// - gymId (String)
/// - name (String)
/// - primaryColorHex (String, z. B. "FF5722" oder "#FF5722")
/// - accentColorHex (String)
/// - logoURL (String)
@JsonSerializable()
class GymConfigDto {
  @JsonKey(name: 'gymId')
  final String gymId;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'primaryColorHex')
  final String primaryColorHex;

  @JsonKey(name: 'accentColorHex')
  final String accentColorHex;

  @JsonKey(name: 'logoURL')
  final String logoUrl;

  const GymConfigDto({
    required this.gymId,
    required this.name,
    required this.primaryColorHex,
    required this.accentColorHex,
    required this.logoUrl,
  });

  /// Erzeugt eine Instanz aus JSON (Firestore-Daten).
  factory GymConfigDto.fromJson(Map<String, dynamic> json) =>
      _$GymConfigDtoFromJson(json);

  /// Konvertiert dieses DTO in eine JSON-Map.
  Map<String, dynamic> toJson() => _$GymConfigDtoToJson(this);
}
