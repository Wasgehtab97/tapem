import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';

part 'user_data_dto.g.dart';

@JsonSerializable()
class UserDataDto {
  @JsonKey(ignore: true)
  late String userId;

  final String email;
  @JsonKey(name: 'gymCode')
  final String gymCode;
  final String role;
  @JsonKey(
    fromJson: _timestampToDate,
    toJson: _dateToTimestamp,
  )
  final DateTime createdAt;

  UserDataDto({
    required this.email,
    required this.gymCode,
    required this.role,
    required this.createdAt,
  });

  factory UserDataDto.fromJson(Map<String, dynamic> json) =>
      _$UserDataDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserDataDtoToJson(this);

  factory UserDataDto.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final dto = UserDataDto.fromJson(data);
    dto.userId = doc.id;
    return dto;
  }

  UserData toModel() => UserData(
        id: userId,
        email: email,
        gymId: gymCode,
        role: role,
        createdAt: createdAt,
      );

  static DateTime _timestampToDate(Timestamp ts) => ts.toDate();
  static Timestamp _dateToTimestamp(DateTime date) =>
      Timestamp.fromDate(date);
}
