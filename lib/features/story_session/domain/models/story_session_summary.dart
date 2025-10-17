import 'package:equatable/equatable.dart';

import 'story_achievement.dart';

class StorySessionSummary extends Equatable {
  final String gymId;
  final String userId;
  final String dayKey;
  final int totalXp;
  final DateTime generatedAt;
  final List<StoryAchievement> achievements;

  const StorySessionSummary({
    required this.gymId,
    required this.userId,
    required this.dayKey,
    required this.totalXp,
    required this.generatedAt,
    required this.achievements,
  });

  Map<String, dynamic> toJson() => {
        'gymId': gymId,
        'userId': userId,
        'dayKey': dayKey,
        'totalXp': totalXp,
        'generatedAt': generatedAt.toIso8601String(),
        'achievements': achievements.map((a) => a.toJson()).toList(),
      };

  factory StorySessionSummary.fromJson(Map<String, dynamic> json) {
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
    );
  }

  StorySessionSummary copyWith({
    int? totalXp,
    DateTime? generatedAt,
    List<StoryAchievement>? achievements,
  }) {
    return StorySessionSummary(
      gymId: gymId,
      userId: userId,
      dayKey: dayKey,
      totalXp: totalXp ?? this.totalXp,
      generatedAt: generatedAt ?? this.generatedAt,
      achievements: achievements ?? this.achievements,
    );
  }

  @override
  List<Object?> get props => [gymId, userId, dayKey, totalXp, generatedAt, achievements];
}
