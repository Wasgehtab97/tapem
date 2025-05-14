// lib/data/dtos/tenant_dto.dart

import 'package:json_annotation/json_annotation.dart';

part 'tenant_dto.g.dart';

@JsonSerializable()
class TenantDto {
  @JsonKey(name: 'gym_id')
  final String gymId;

  @JsonKey(name: 'display_name')
  final String displayName;

  TenantDto({
    required this.gymId,
    required this.displayName,
  });

  factory TenantDto.fromJson(Map<String, dynamic> json) =>
      _$TenantDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TenantDtoToJson(this);
}
