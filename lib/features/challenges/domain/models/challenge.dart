import "package:cloud_firestore/cloud_firestore.dart";
class Challenge {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final int goalXp;

  Challenge({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.goalXp,
  });

  Challenge copyWith({
    String? id,
    String? title,
    DateTime? start,
    DateTime? end,
    int? goalXp,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      goalXp: goalXp ?? this.goalXp,
    );
  }

  factory Challenge.fromMap(String id, Map<String, dynamic> map) => Challenge(
        id: id,
        title: map['title'] as String? ?? '',
        start: (map['start'] as Timestamp?)?.toDate() ?? DateTime.now(),
        end: (map['end'] as Timestamp?)?.toDate() ?? DateTime.now(),
        goalXp: map['goalXp'] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'start': Timestamp.fromDate(start),
        'end': Timestamp.fromDate(end),
        'goalXp': goalXp,
      };
}
