import 'package:cloud_firestore/cloud_firestore.dart';

class Badge {
  final String id;
  final String challengeId;
  final String userId;
  final DateTime awardedAt;

  Badge({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.awardedAt,
  });

  factory Badge.fromMap(String id, Map<String, dynamic> map) => Badge(
        id: id,
        challengeId: map['challengeId'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        awardedAt: (map['awardedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'challengeId': challengeId,
        'userId': userId,
        'awardedAt': Timestamp.fromDate(awardedAt),
      };
}
