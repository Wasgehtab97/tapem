// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDataDto _$UserDataDtoFromJson(Map<String, dynamic> json) => UserDataDto(
  email: json['email'] as String,
  gymCode: json['gymCode'] as String,
  role: json['role'] as String,
  createdAt: UserDataDto._timestampToDate(json['createdAt'] as Timestamp),
);

Map<String, dynamic> _$UserDataDtoToJson(UserDataDto instance) =>
    <String, dynamic>{
      'email': instance.email,
      'gymCode': instance.gymCode,
      'role': instance.role,
      'createdAt': UserDataDto._dateToTimestamp(instance.createdAt),
    };
