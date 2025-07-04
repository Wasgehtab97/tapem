import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';

class UserDataDto {
  final String userId;
  final String email;
  final String emailLower;
  final String? userName;
  final String? userNameLower;
  final List<String> gymCodes;
  final bool showInLeaderboard;
  final String role;
  final DateTime createdAt;

  UserDataDto({
    required this.userId,
    required this.email,
    required this.emailLower,
    this.userName,
    this.userNameLower,
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
      emailLower: data['emailLower'] as String? ??
          (data['email'] as String).toLowerCase(),
      userName: data['username'] as String?,
      userNameLower: data['usernameLower'] as String?,
      gymCodes: List<String>.from(data['gymCodes'] ?? []),
      showInLeaderboard: data['showInLeaderboard'] as bool? ?? true,
      role: data['role'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'emailLower': emailLower,
    if (userName != null) 'username': userName,
    if (userNameLower != null) 'usernameLower': userNameLower,
    'gymCodes': gymCodes,
    'showInLeaderboard': showInLeaderboard,
    'role': role,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  UserData toModel() {
    return UserData(
      id: userId,
      email: email,
      userName: userName,
      gymCodes: gymCodes,
      showInLeaderboard: showInLeaderboard,
      role: role,
      createdAt: createdAt,
    );
  }
}
