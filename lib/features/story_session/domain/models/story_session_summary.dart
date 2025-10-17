import 'package:equatable/equatable.dart';

import 'story_achievement.dart';

class StorySessionStats extends Equatable {
  final int exerciseCount;
  final int setCount;
  final int durationMs;

  const StorySessionStats({
    required this.exerciseCount,
    required this.setCount,
    required this.durationMs,
  });

  const StorySessionStats.empty()
      : exerciseCount = 0,
        setCount = 0,
        durationMs = 0;

  Duration get duration => Duration(milliseconds: durationMs);

  Map<String, dynamic> toJson() => {
        'exerciseCount': exerciseCount,
        'setCount': setCount,
        'durationMs': durationMs,
      };

  factory StorySessionStats.fromJson(Map<String, dynamic> json) {
    return StorySessionStats(
      exerciseCount: (json['exerciseCount'] as num?)?.toInt() ?? 0,
      setCount: (json['setCount'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
    );
  }

  StorySessionStats copyWith({
    int? exerciseCount,
    int? setCount,
    int? durationMs,
  }) {
    return StorySessionStats(
      exerciseCount: exerciseCount ?? this.exerciseCount,
      setCount: setCount ?? this.setCount,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  @override
  List<Object?> get props => [exerciseCount, setCount, durationMs];
}

class StorySessionSummary extends Equatable {
  final String gymId;
  final String userId;
  final String dayKey;
  final int totalXp;
  final DateTime generatedAt;
  final List<StoryAchievement> achievements;
  final StorySessionStats stats;

  const StorySessionSummary({
    required this.gymId,
    required this.userId,
    required this.dayKey,
    required this.totalXp,
    required this.generatedAt,
    required this.achievements,
    required this.stats,
  });

  Map<String, dynamic> toJson() => {
        'gymId': gymId,
        'userId': userId,
        'dayKey': dayKey,
        'totalXp': totalXp,
        'generatedAt': generatedAt.toIso8601String(),
        'achievements': achievements.map((a) => a.toJson()).toList(),
        'stats': stats.toJson(),
      };

  factory StorySessionSummary.fromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'];
    return StorySessionSummary(
      gymId: json['gymId'] as String,
      userId: json['userId'] as String,
      dayKey: json['dayKey'] as String,
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      generatedAt:
          DateTime.tryParse(json['generatedAt'] as String? ?? '') ?? DateTime.now(),
      achievements: (json['achievements'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StoryAchievement.fromJson)
          .toList(),
      stats: statsJson is Map<String, dynamic>
          ? StorySessionStats.fromJson(statsJson)
          : const StorySessionStats.empty(),
    );
  }

  StorySessionSummary copyWith({
    int? totalXp,
    DateTime? generatedAt,
    List<StoryAchievement>? achievements,
    StorySessionStats? stats,
  }) {
    return StorySessionSummary(
      gymId: gymId,
      userId: userId,
      dayKey: dayKey,
      totalXp: totalXp ?? this.totalXp,
      generatedAt: generatedAt ?? this.generatedAt,
      achievements: achievements ?? this.achievements,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props =>
      [gymId, userId, dayKey, totalXp, generatedAt, achievements, stats];
}
