import 'package:cloud_firestore/cloud_firestore.dart';

class CompletedChallenge {
  final String id;
  final String title;
  final DateTime completedAt;

  CompletedChallenge({
    required this.id,
    required this.title,
    required this.completedAt,
  });

  factory CompletedChallenge.fromMap(String id, Map<String, dynamic> map) =>
      CompletedChallenge(
        id: id,
        title: map['title'] as String? ?? '',
        completedAt:
            (map['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
    'title': title,
    'completedAt': Timestamp.fromDate(completedAt),
  };
}
