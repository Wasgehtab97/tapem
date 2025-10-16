class FavoriteExerciseUsage {
  const FavoriteExerciseUsage({
    required this.name,
    required this.sessionCount,
  });

  final String name;
  final int sessionCount;

  Map<String, dynamic> toJson() => {
        'name': name,
        'sessionCount': sessionCount,
      };

  factory FavoriteExerciseUsage.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'];
    final rawCount = json['sessionCount'];
    return FavoriteExerciseUsage(
      name: rawName is String && rawName.trim().isNotEmpty ? rawName : '—',
      sessionCount: rawCount is num ? rawCount.toInt() : 0,
    );
  }
}
