import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackEntry {
  final String id;
  final String gymId;
  final String deviceId;
  final String userId;
  final String text;
  final DateTime createdAt;
  final bool isDone;

  FeedbackEntry({
    required this.id,
    required this.gymId,
    required this.deviceId,
    required this.userId,
    required this.text,
    required this.createdAt,
    required this.isDone,
  });

  factory FeedbackEntry.fromMap(
    String id,
    Map<String, dynamic> data,
    String gymId,
  ) {
    return FeedbackEntry(
      id: id,
      gymId: gymId,
      deviceId: data['deviceId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDone: data['isDone'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'deviceId': deviceId,
    'userId': userId,
    'text': text,
    'createdAt': Timestamp.fromDate(createdAt),
    'isDone': isDone,
  };
}
