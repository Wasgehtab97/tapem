class CommunityStats {
  const CommunityStats({
    required this.totalSessions,
    required this.totalExercises,
    required this.totalSets,
    required this.totalReps,
    required this.totalVolumeKg,
    this.dayKey,
    this.date,
  });

  final int totalSessions;
  final int totalExercises;
  final int totalSets;
  final int totalReps;
  final double totalVolumeKg;
  final String? dayKey;
  final DateTime? date;

  static const CommunityStats zero = CommunityStats(
    totalSessions: 0,
    totalExercises: 0,
    totalSets: 0,
    totalReps: 0,
    totalVolumeKg: 0,
  );

  bool get hasData =>
      totalSessions > 0 ||
      totalExercises > 0 ||
      totalSets > 0 ||
      totalReps > 0 ||
      totalVolumeKg > 0.0;

  CommunityStats copyWith({
    int? totalSessions,
    int? totalExercises,
    int? totalSets,
    int? totalReps,
    double? totalVolumeKg,
    String? dayKey,
    DateTime? date,
  }) {
    return CommunityStats(
      totalSessions: totalSessions ?? this.totalSessions,
      totalExercises: totalExercises ?? this.totalExercises,
      totalSets: totalSets ?? this.totalSets,
      totalReps: totalReps ?? this.totalReps,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
      dayKey: dayKey ?? this.dayKey,
      date: date ?? this.date,
    );
  }

  CommunityStats operator +(CommunityStats other) {
    return CommunityStats(
      totalSessions: totalSessions + other.totalSessions,
      totalExercises: totalExercises + other.totalExercises,
      totalSets: totalSets + other.totalSets,
      totalReps: totalReps + other.totalReps,
      totalVolumeKg: totalVolumeKg + other.totalVolumeKg,
    );
  }
}
