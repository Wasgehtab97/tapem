import 'package:cloud_firestore/cloud_firestore.dart';

class FriendMessage {
  const FriendMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt;

  factory FriendMessage.fromMap(String id, Map<String, dynamic> data) {
    return FriendMessage(
      id: id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
