/// Domain-Modell für einen Benutzer.
class UserData {
  final String id;
  final String email;
  final String displayName;
  final DateTime joinedAt;
  final int totalExperience;
  final int currentStreak;

  const UserData({
    required this.id,
    required this.email,
    required this.displayName,
    required this.joinedAt,
    required this.totalExperience,
    required this.currentStreak,
  });

  @override
  String toString() =>
      'UserData(id: $id, email: $email, xp: $totalExperience, streak: $currentStreak)';
}
