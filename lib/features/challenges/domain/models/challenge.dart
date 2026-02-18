import "package:cloud_firestore/cloud_firestore.dart";

enum ChallengeGoalType { deviceSets, workoutDays }

extension ChallengeGoalTypeCodec on ChallengeGoalType {
  String toFirestoreValue() {
    switch (this) {
      case ChallengeGoalType.deviceSets:
        return 'device_sets';
      case ChallengeGoalType.workoutDays:
        return 'workout_days';
    }
  }
}

ChallengeGoalType challengeGoalTypeFromFirestore(dynamic raw) {
  final value = (raw as String?)?.trim().toLowerCase();
  switch (value) {
    case 'workout_days':
    case 'workout_frequency':
      return ChallengeGoalType.workoutDays;
    case 'device_sets':
    default:
      return ChallengeGoalType.deviceSets;
  }
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final ChallengeGoalType goalType;
  final List<String> deviceIds;
  final int minSets;
  final int targetWorkouts;
  final int durationWeeks;
  final int xpReward;

  Challenge({
    required this.id,
    required this.title,
    this.description = '',
    required this.start,
    required this.end,
    this.goalType = ChallengeGoalType.deviceSets,
    required this.deviceIds,
    this.minSets = 0,
    this.targetWorkouts = 0,
    this.durationWeeks = 1,
    this.xpReward = 0,
  });

  bool get isWorkoutChallenge => goalType == ChallengeGoalType.workoutDays;

  int get targetCount => isWorkoutChallenge ? targetWorkouts : minSets;

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? start,
    DateTime? end,
    ChallengeGoalType? goalType,
    List<String>? deviceIds,
    int? minSets,
    int? targetWorkouts,
    int? durationWeeks,
    int? xpReward,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      start: start ?? this.start,
      end: end ?? this.end,
      goalType: goalType ?? this.goalType,
      deviceIds: deviceIds ?? this.deviceIds,
      minSets: minSets ?? this.minSets,
      targetWorkouts: targetWorkouts ?? this.targetWorkouts,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  factory Challenge.fromMap(String id, Map<String, dynamic> map) {
    final parsedDurationWeeks = _parseInt(map['durationWeeks']);
    return Challenge(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      start: (map['start'] as Timestamp?)?.toDate() ?? DateTime.now(),
      end: (map['end'] as Timestamp?)?.toDate() ?? DateTime.now(),
      goalType: challengeGoalTypeFromFirestore(map['goalType']),
      deviceIds: (map['deviceIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      minSets: _parseInt(map['minSets']),
      targetWorkouts: _parseInt(map['targetWorkouts']),
      durationWeeks: parsedDurationWeeks <= 0 ? 1 : parsedDurationWeeks,
      xpReward: _parseInt(map['xpReward']),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'start': Timestamp.fromDate(start),
    'end': Timestamp.fromDate(end),
    'goalType': goalType.toFirestoreValue(),
    'deviceIds': deviceIds,
    'minSets': minSets,
    'targetWorkouts': targetWorkouts,
    'durationWeeks': durationWeeks,
    'xpReward': xpReward,
  };
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
