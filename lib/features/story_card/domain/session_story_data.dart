import 'package:flutter/material.dart';

/// Describes the story card content for a closed training session.
@immutable
class SessionStoryData {
  final String sessionId;
  final String userId;
  final String gymId;
  final String? gymName;
  final DateTime occurredAt;
  final double xpTotal;
  final double baseXp;
  final double bonusXp;
  final int setCount;
  final int exerciseCount;
  final double totalVolume;
  final double durationMinutes;
  final List<SessionStoryBadge> badges;
  final List<SessionStoryMuscle> muscles;

  const SessionStoryData({
    required this.sessionId,
    required this.userId,
    required this.gymId,
    required this.gymName,
    required this.occurredAt,
    required this.xpTotal,
    required this.baseXp,
    required this.bonusXp,
    required this.setCount,
    required this.exerciseCount,
    required this.totalVolume,
    required this.durationMinutes,
    required this.badges,
    required this.muscles,
  });

  bool get hasPrs => badges.isNotEmpty;
  bool get hasMuscles => muscles.isNotEmpty;
}

@immutable
class SessionStoryBadge {
  final SessionStoryBadgeType type;
  final String label;
  final String? deltaLabel;
  final IconData icon;
  final double? delta;
  final double? value;
  final String? unit;
  final double? setWeight;
  final int? setReps;

  const SessionStoryBadge({
    required this.type,
    required this.label,
    required this.icon,
    this.deltaLabel,
    this.delta,
    this.value,
    this.unit,
    this.setWeight,
    this.setReps,
  });
}

enum SessionStoryBadgeType {
  firstDevice,
  firstExercise,
  estimatedOneRepMax,
  volume,
}

@immutable
class SessionStoryMuscle {
  final String id;
  final String displayName;
  final double xp;

  const SessionStoryMuscle({
    required this.id,
    required this.displayName,
    required this.xp,
  });
}

@immutable
class SessionStoryPrEvent {
  final String id;
  final SessionStoryBadgeType type;
  final String? deviceId;
  final String? exerciseId;
  final double? value;
  final double? previousBest;
  final double? delta;
  final String? unit;
  final double? bestSetWeight;
  final int? bestSetReps;

  const SessionStoryPrEvent({
    required this.id,
    required this.type,
    this.deviceId,
    this.exerciseId,
    this.value,
    this.previousBest,
    this.delta,
    this.unit,
    this.bestSetWeight,
    this.bestSetReps,
  });
}
