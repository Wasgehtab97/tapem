import 'package:equatable/equatable.dart';

enum StoryAchievementType {
  dailyXp,
  newDevice,
  newExercise,
  personalRecord,
}

class StoryAchievement extends Equatable {
  final StoryAchievementType type;
  final String? deviceName;
  final String? exerciseName;
  final double? e1rm;
  final int? xp;
  final double? prWeight;
  final int? prReps;

  const StoryAchievement({
    required this.type,
    this.deviceName,
    this.exerciseName,
    this.e1rm,
    this.xp,
    this.prWeight,
    this.prReps,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (deviceName != null) 'deviceName': deviceName,
        if (exerciseName != null) 'exerciseName': exerciseName,
        if (e1rm != null) 'e1rm': e1rm,
        if (xp != null) 'xp': xp,
        if (prWeight != null) 'prWeight': prWeight,
        if (prReps != null) 'prReps': prReps,
      };

  factory StoryAchievement.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? StoryAchievementType.dailyXp.name;
    final type = StoryAchievementType.values.firstWhere(
      (element) => element.name == typeName,
      orElse: () => StoryAchievementType.dailyXp,
    );
    return StoryAchievement(
      type: type,
      deviceName: json['deviceName'] as String?,
      exerciseName: json['exerciseName'] as String?,
      e1rm: (json['e1rm'] as num?)?.toDouble(),
      xp: (json['xp'] as num?)?.toInt(),
      prWeight: (json['prWeight'] as num?)?.toDouble(),
      prReps: (json['prReps'] as num?)?.toInt(),
    );
  }

  StoryAchievement copyWith({
    StoryAchievementType? type,
    String? deviceName,
    String? exerciseName,
    double? e1rm,
    int? xp,
    double? prWeight,
    int? prReps,
  }) {
    return StoryAchievement(
      type: type ?? this.type,
      deviceName: deviceName ?? this.deviceName,
      exerciseName: exerciseName ?? this.exerciseName,
      e1rm: e1rm ?? this.e1rm,
      xp: xp ?? this.xp,
      prWeight: prWeight ?? this.prWeight,
      prReps: prReps ?? this.prReps,
    );
  }

  @override
  List<Object?> get props => [type, deviceName, exerciseName, e1rm, xp, prWeight, prReps];
}
