// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gym_config_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GymConfigDto _$GymConfigDtoFromJson(Map<String, dynamic> json) => GymConfigDto(
  gymId: json['gym_id'] as String,
  name: json['name'] as String,
  logoUrl: json['logo_url'] as String,
  themeColors: Map<String, String>.from(json['theme_colors'] as Map),
);

Map<String, dynamic> _$GymConfigDtoToJson(GymConfigDto instance) =>
    <String, dynamic>{
      'gym_id': instance.gymId,
      'name': instance.name,
      'logo_url': instance.logoUrl,
      'theme_colors': instance.themeColors,
    };
