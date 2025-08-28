class UserData {
  final String id;
  final String email;
  final String? userName;
  final List<String> gymCodes;
  final bool showInLeaderboard;
  final bool publicProfile;
  final String role;
  final DateTime createdAt;

  const UserData({
    required this.id,
    required this.email,
    this.userName,
    required this.gymCodes,
    required this.showInLeaderboard,
    required this.publicProfile,
    required this.role,
    required this.createdAt,
  });

  UserData copyWith({
    String? id,
    String? email,
    String? userName,
    List<String>? gymCodes,
    bool? showInLeaderboard,
    bool? publicProfile,
    String? role,
    DateTime? createdAt,
  }) {
    return UserData(
      id: id ?? this.id,
      email: email ?? this.email,
      userName: userName ?? this.userName,
      gymCodes: gymCodes ?? this.gymCodes,
      showInLeaderboard: showInLeaderboard ?? this.showInLeaderboard,
      publicProfile: publicProfile ?? this.publicProfile,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
