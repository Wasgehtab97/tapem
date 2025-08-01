class UserData {
  final String id;
  final String email;
  final String? userName;
  final List<String> gymCodes;
  final bool showInLeaderboard;
  final String role;
  final DateTime createdAt;

  const UserData({
    required this.id,
    required this.email,
    this.userName,
    required this.gymCodes,
    required this.showInLeaderboard,
    required this.role,
    required this.createdAt,
  });

  UserData copyWith({
    String? id,
    String? email,
    String? userName,
    List<String>? gymCodes,
    bool? showInLeaderboard,
    String? role,
    DateTime? createdAt,
  }) {
    return UserData(
      id: id ?? this.id,
      email: email ?? this.email,
      userName: userName ?? this.userName,
      gymCodes: gymCodes ?? this.gymCodes,
      showInLeaderboard: showInLeaderboard ?? this.showInLeaderboard,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
