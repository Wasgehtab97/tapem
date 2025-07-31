import "package:cloud_firestore/cloud_firestore.dart";

class Challenge {
  final String id;
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final List<String> deviceIds;
  final int minSets;
  final int xpReward;

  Challenge({
    required this.id,
    required this.title,
    this.description = '',
    required this.start,
    required this.end,
    required this.deviceIds,
    this.minSets = 0,
    this.xpReward = 0,
  });

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? start,
    DateTime? end,
    List<String>? deviceIds,
    int? minSets,
    int? xpReward,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      start: start ?? this.start,
      end: end ?? this.end,
      deviceIds: deviceIds ?? this.deviceIds,
      minSets: minSets ?? this.minSets,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  factory Challenge.fromMap(String id, Map<String, dynamic> map) => Challenge(
    id: id,
    title: map['title'] as String? ?? '',
    description: map['description'] as String? ?? '',
    start: (map['start'] as Timestamp?)?.toDate() ?? DateTime.now(),
    end: (map['end'] as Timestamp?)?.toDate() ?? DateTime.now(),
    deviceIds:
        (map['deviceIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
    minSets: _parseInt(map['minSets']),
    xpReward: _parseInt(map['xpReward']),
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'start': Timestamp.fromDate(start),
    'end': Timestamp.fromDate(end),
    'deviceIds': deviceIds,
    'minSets': minSets,
    'xpReward': xpReward,
  };
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
