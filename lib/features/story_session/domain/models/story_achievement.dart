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

  const StoryAchievement({
    required this.type,
    this.deviceName,
    this.exerciseName,
    this.e1rm,
    this.xp,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (deviceName != null) 'deviceName': deviceName,
        if (exerciseName != null) 'exerciseName': exerciseName,
        if (e1rm != null) 'e1rm': e1rm,
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
      xp: (json['xp'] as num?)?.toInt(),
    );
  }

  StoryAchievement copyWith({
    StoryAchievementType? type,
    String? deviceName,
    String? exerciseName,
    double? e1rm,
    int? xp,
  }) {
    return StoryAchievement(
      type: type ?? this.type,
      deviceName: deviceName ?? this.deviceName,
      exerciseName: exerciseName ?? this.exerciseName,
      e1rm: e1rm ?? this.e1rm,
      xp: xp ?? this.xp,
    );
  }

  @override
  List<Object?> get props => [type, deviceName, exerciseName, e1rm, xp];
}
