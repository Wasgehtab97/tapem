// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gym_config_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GymConfigDto _$GymConfigDtoFromJson(Map<String, dynamic> json) => GymConfigDto(
  gymId: json['gymId'] as String,
  name: json['name'] as String,
  primaryColorHex: json['primaryColorHex'] as String,
  accentColorHex: json['accentColorHex'] as String,
  logoUrl: json['logoURL'] as String,
);

Map<String, dynamic> _$GymConfigDtoToJson(GymConfigDto instance) =>
    <String, dynamic>{
      'gymId': instance.gymId,
      'name': instance.name,
      'primaryColorHex': instance.primaryColorHex,
      'accentColorHex': instance.accentColorHex,
      'logoURL': instance.logoUrl,
    };
