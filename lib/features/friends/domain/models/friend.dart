import "package:cloud_firestore/cloud_firestore.dart";

class Friend {
  Friend({required this.friendUid, required this.since, this.createdAt, this.updatedAt});

  final String friendUid;
  final DateTime since;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Friend.fromMap(String id, Map<String, dynamic> data) {
    return Friend(
      friendUid: id,
      since: (data['since'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
