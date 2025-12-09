class TrainingPlanStats {
  final int completions;
  final DateTime? firstCompletedAt;
  final DateTime? lastCompletedAt;

  const TrainingPlanStats({
    required this.completions,
    this.firstCompletedAt,
    this.lastCompletedAt,
  });

  factory TrainingPlanStats.empty() => const TrainingPlanStats(completions: 0);

  factory TrainingPlanStats.fromJson(Map<String, dynamic> json) {
    return TrainingPlanStats(
      completions: (json['completions'] as int?) ?? 0,
      firstCompletedAt: json['firstCompletedAt'] != null
          ? DateTime.tryParse(json['firstCompletedAt'] as String)
          : null,
      lastCompletedAt: json['lastCompletedAt'] != null
          ? DateTime.tryParse(json['lastCompletedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completions': completions,
      if (firstCompletedAt != null)
        'firstCompletedAt': firstCompletedAt!.toIso8601String(),
      if (lastCompletedAt != null)
        'lastCompletedAt': lastCompletedAt!.toIso8601String(),
    };
  }
}
