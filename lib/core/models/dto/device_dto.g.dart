// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceDto _$DeviceDtoFromJson(Map<String, dynamic> json) => DeviceDto(
  deviceId: (json['id'] as num).toInt(),
  documentId: json['documentId'] as String,
  name: json['name'] as String,
  exerciseMode: json['exercise_mode'] as String,
  secretCode: json['secret_code'] as String,
);

Map<String, dynamic> _$DeviceDtoToJson(DeviceDto instance) => <String, dynamic>{
  'id': instance.deviceId,
  'documentId': instance.documentId,
  'name': instance.name,
  'exercise_mode': instance.exerciseMode,
  'secret_code': instance.secretCode,
};
