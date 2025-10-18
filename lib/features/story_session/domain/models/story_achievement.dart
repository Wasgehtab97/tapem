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
  final double? topSetWeight;
  final int? topSetReps;
  final int? xp;

  const StoryAchievement({
    required this.type,
    this.deviceName,
    this.exerciseName,
    this.e1rm,
    this.topSetWeight,
    this.topSetReps,
    this.xp,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (deviceName != null) 'deviceName': deviceName,
        if (exerciseName != null) 'exerciseName': exerciseName,
        if (e1rm != null) 'e1rm': e1rm,
        if (topSetWeight != null) 'topSetWeight': topSetWeight,
        if (topSetReps != null) 'topSetReps': topSetReps,
        if (xp != null) 'xp': xp,
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
      topSetWeight: (json['topSetWeight'] as num?)?.toDouble(),
      topSetReps: (json['topSetReps'] as num?)?.toInt(),
      xp: (json['xp'] as num?)?.toInt(),
    );
  }

  StoryAchievement copyWith({
    StoryAchievementType? type,
    String? deviceName,
    String? exerciseName,
    double? e1rm,
    double? topSetWeight,
    int? topSetReps,
    int? xp,
  }) {
    return StoryAchievement(
      type: type ?? this.type,
      deviceName: deviceName ?? this.deviceName,
      exerciseName: exerciseName ?? this.exerciseName,
      e1rm: e1rm ?? this.e1rm,
      topSetWeight: topSetWeight ?? this.topSetWeight,
      topSetReps: topSetReps ?? this.topSetReps,
      xp: xp ?? this.xp,
    );
  }

  @override
  List<Object?> get props => [
        type,
        deviceName,
        exerciseName,
        e1rm,
        topSetWeight,
        topSetReps,
        xp,
      ];
}
