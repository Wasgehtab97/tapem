import 'package:flutter/foundation.dart';

@immutable
class WorkoutDeviceXpState {
  const WorkoutDeviceXpState({
    required this.xp,
    required this.level,
    this.updatedAt,
  });

  static const WorkoutDeviceXpState initial = WorkoutDeviceXpState(
    xp: 0,
    level: 1,
  );

  final int xp;
  final int level;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'xp': xp,
      'level': level,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory WorkoutDeviceXpState.fromJson(Map<String, dynamic> json) {
    return WorkoutDeviceXpState(
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}
