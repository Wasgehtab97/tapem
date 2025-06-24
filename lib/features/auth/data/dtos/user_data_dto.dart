import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';

class UserDataDto {
  final String userId;
  final String email;
  final List<String> gymCodes;
  final bool showInLeaderboard;
  final String role;
  final DateTime createdAt;

  UserDataDto({
    required this.userId,
    required this.email,
    required this.gymCodes,
    required this.showInLeaderboard,
    required this.role,
    required this.createdAt,
  });

  factory UserDataDto.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserDataDto(
      userId: doc.id,
      email: data['email'] as String,
      gymCodes: List<String>.from(data['gymCodes'] ?? []),
      showInLeaderboard: data['showInLeaderboard'] as bool? ?? true,
      role: data['role'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'gymCodes': gymCodes,
    'showInLeaderboard': showInLeaderboard,
    'role': role,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  UserData toModel() {
    return UserData(
      id: userId,
      email: email,
      gymCodes: gymCodes,
      showInLeaderboard: showInLeaderboard,
      role: role,
      createdAt: createdAt,
    );
  }
}
