import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  Friend({required this.friendUid, this.createdAt});

  final String friendUid;
  final DateTime? createdAt;

  factory Friend.fromMap(String id, Map<String, dynamic> data) {
    return Friend(
      friendUid: id,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
