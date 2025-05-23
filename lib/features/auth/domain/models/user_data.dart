class UserData {
  final String id;
  final String email;
  final String gymId;
  final String role;
  final DateTime createdAt;

  const UserData({
    required this.id,
    required this.email,
    required this.gymId,
    required this.role,
    required this.createdAt,
  });

  /// Ermöglicht partielles Überschreiben von Feldern
  UserData copyWith({
    String? id,
    String? email,
    String? gymId,
    String? role,
    DateTime? createdAt,
  }) {
    return UserData(
      id:          id          ?? this.id,
      email:       email       ?? this.email,
      gymId:       gymId       ?? this.gymId,
      role:        role        ?? this.role,
      createdAt:   createdAt   ?? this.createdAt,
    );
  }
}
