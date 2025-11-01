class CommunityStats {
  const CommunityStats({
    required this.totalReps,
    required this.totalVolumeKg,
    required this.workoutCount,
    this.dayKey,
    this.date,
  });

  final int totalReps;
  final double totalVolumeKg;
  final int workoutCount;
  final String? dayKey;
  final DateTime? date;

  static const CommunityStats zero = CommunityStats(
    totalReps: 0,
    totalVolumeKg: 0,
    workoutCount: 0,
  );

  bool get hasData =>
      totalReps > 0 || totalVolumeKg > 0.0 || workoutCount > 0;

  CommunityStats copyWith({
    int? totalReps,
    double? totalVolumeKg,
    int? workoutCount,
    String? dayKey,
    DateTime? date,
  }) {
    return CommunityStats(
      totalReps: totalReps ?? this.totalReps,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
      workoutCount: workoutCount ?? this.workoutCount,
      dayKey: dayKey ?? this.dayKey,
      date: date ?? this.date,
    );
  }

  CommunityStats operator +(CommunityStats other) {
    return CommunityStats(
      totalReps: totalReps + other.totalReps,
      totalVolumeKg: totalVolumeKg + other.totalVolumeKg,
      workoutCount: workoutCount + other.workoutCount,
    );
  }
}
