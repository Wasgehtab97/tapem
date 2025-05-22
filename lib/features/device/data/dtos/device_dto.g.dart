// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceDto _$DeviceDtoFromJson(Map<String, dynamic> json) => DeviceDto(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String? ?? '',
  nfcCode: json['nfcCode'] as String?,
);

Map<String, dynamic> _$DeviceDtoToJson(DeviceDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'nfcCode': instance.nfcCode,
};
