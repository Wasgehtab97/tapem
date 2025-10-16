class FavoriteExerciseUsage {
  FavoriteExerciseUsage({
    required this.name,
    required this.sessionCount,
    this.id = '',
  });

  final String id;
  final String name;
  final int sessionCount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sessionCount': sessionCount,
    };
  }

  factory FavoriteExerciseUsage.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '—';
    final sessionCount = json['sessionCount'];
    return FavoriteExerciseUsage(
      id: (json['id'] as String?) ?? '',
      name: name,
      sessionCount: sessionCount is int
          ? sessionCount
          : int.tryParse(sessionCount?.toString() ?? '') ?? 0,
    );
  }
}
