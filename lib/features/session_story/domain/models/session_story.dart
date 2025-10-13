import 'package:flutter/foundation.dart';

import 'package:tapem/features/training_details/domain/models/session.dart';

@immutable
class SessionStory {
  final String dayKey;
  final DateTime day;
  final List<SessionStoryHighlight> highlights;
  final SessionStoryXpSummary xpSummary;
  final Duration? totalDuration;
  final int sessionCount;
  final List<Session> sessions;

  const SessionStory({
    required this.dayKey,
    required this.day,
    required this.highlights,
    required this.xpSummary,
    required this.sessionCount,
    required this.sessions,
    this.totalDuration,
  });

  SessionStory copyWith({
    List<SessionStoryHighlight>? highlights,
    SessionStoryXpSummary? xpSummary,
    Duration? totalDuration,
    int? sessionCount,
    List<Session>? sessions,
  }) {
    return SessionStory(
      dayKey: dayKey,
      day: day,
      highlights: highlights ?? this.highlights,
      xpSummary: xpSummary ?? this.xpSummary,
      sessionCount: sessionCount ?? this.sessionCount,
      sessions: sessions ?? this.sessions,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }
}

enum SessionStoryHighlightType {
  firstDevice,
  firstExercise,
  e1rmPr,
  volumePr,
}

@immutable
class SessionStoryHighlight {
  final SessionStoryHighlightType type;
  final String deviceName;
  final String canonicalDeviceName;
  final String? exerciseName;
  final double? metricValue;

  const SessionStoryHighlight({
    required this.type,
    required this.deviceName,
    required this.canonicalDeviceName,
    this.exerciseName,
    this.metricValue,
  });
}

@immutable
class SessionStoryXpSummary {
  final int dailyXp;
  final List<SessionStoryDeviceXp> deviceXp;
  final List<SessionStoryMuscleXp> muscleXp;

  const SessionStoryXpSummary({
    required this.dailyXp,
    required this.deviceXp,
    required this.muscleXp,
  });
}

@immutable
class SessionStoryDeviceXp {
  final String deviceId;
  final String deviceName;
  final String canonicalDeviceName;
  final List<String> exerciseNames;
  final int xp;
  final int sessionCount;

  const SessionStoryDeviceXp({
    required this.deviceId,
    required this.deviceName,
    required this.canonicalDeviceName,
    required this.exerciseNames,
    required this.xp,
    required this.sessionCount,
  });
}

@immutable
class SessionStoryMuscleXp {
  final String muscleGroupId;
  final int xp;

  const SessionStoryMuscleXp({
    required this.muscleGroupId,
    required this.xp,
  });
}
