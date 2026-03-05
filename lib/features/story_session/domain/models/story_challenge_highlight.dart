import 'package:equatable/equatable.dart';

class StoryChallengeHighlight extends Equatable {
  final String challengeId;
  final String title;
  final String description;
  final String goalType;
  final int progress;
  final int target;
  final int xpReward;
  final int durationWeeks;
  final DateTime start;
  final DateTime end;

  const StoryChallengeHighlight({
    required this.challengeId,
    required this.title,
    this.description = '',
    required this.goalType,
    required this.progress,
    required this.target,
    required this.xpReward,
    required this.durationWeeks,
    required this.start,
    required this.end,
  });

  bool get isCompleted => target > 0 && progress >= target;
  double get progressRatio {
    if (target <= 0) return 0;
    return (progress / target).clamp(0, 1).toDouble();
  }

  Map<String, dynamic> toJson() => {
    'challengeId': challengeId,
    'title': title,
    'description': description,
    'goalType': goalType,
    'progress': progress,
    'target': target,
    'xpReward': xpReward,
    'durationWeeks': durationWeeks,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
  };

  factory StoryChallengeHighlight.fromJson(Map<String, dynamic> json) {
    return StoryChallengeHighlight(
      challengeId: (json['challengeId'] as String? ?? '').trim(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      goalType: (json['goalType'] as String? ?? '').trim(),
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      target: (json['target'] as num?)?.toInt() ?? 0,
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
      durationWeeks: (json['durationWeeks'] as num?)?.toInt() ?? 1,
      start:
          DateTime.tryParse(json['start'] as String? ?? '') ?? DateTime.now(),
      end: DateTime.tryParse(json['end'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    challengeId,
    title,
    description,
    goalType,
    progress,
    target,
    xpReward,
    durationWeeks,
    start,
    end,
  ];
}
