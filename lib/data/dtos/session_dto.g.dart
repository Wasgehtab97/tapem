// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionDto _$SessionDtoFromJson(Map<String, dynamic> json) => SessionDto(
  id: json['id'] as String,
  trainingDate: const TimestampConverter().fromJson(
    json['training_date'] as Timestamp,
  ),
  data:
      (json['data'] as List<dynamic>)
          .map((e) => SetDto.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$SessionDtoToJson(SessionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'training_date': const TimestampConverter().toJson(instance.trainingDate),
      'data': instance.data.map((e) => e.toJson()).toList(),
    };

SetDto _$SetDtoFromJson(Map<String, dynamic> json) => SetDto(
  setNumber: (json['set_number'] as num).toInt(),
  weight: json['weight'] as String,
  reps: (json['reps'] as num).toInt(),
);

Map<String, dynamic> _$SetDtoToJson(SetDto instance) => <String, dynamic>{
  'set_number': instance.setNumber,
  'weight': instance.weight,
  'reps': instance.reps,
};
