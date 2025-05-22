// lib/features/auth/data/dtos/user_data_dto.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';

class UserDataDto {
  String userId;
  final String email;
  final String gymCode;
  final String role;
  final DateTime createdAt;

  UserDataDto({
    required this.userId,
    required this.email,
    required this.gymCode,
    required this.role,
    required this.createdAt,
  });

  factory UserDataDto.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserDataDto(
      userId: doc.id,
      email: data['email'] as String,
      gymCode: data['gymCode'] as String,
      role: data['role'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'gymCode': gymCode,
        'role': role,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Wandelt dieses DTO in das Domain-Model um
  UserData toModel() {
    return UserData(
      id: userId,
      email: email,
      gymId: gymCode,
      role: role,
      createdAt: createdAt,
    );
  }
}
