import 'package:cloud_firestore/cloud_firestore.dart';

class FriendChatSummary {
  const FriendChatSummary({
    required this.friendUid,
    required this.conversationId,
    required this.hasUnread,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
  });

  final String friendUid;
  final String conversationId;
  final bool hasUnread;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;

  FriendChatSummary copyWith({
    bool? hasUnread,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
  }) {
    return FriendChatSummary(
      friendUid: friendUid,
      conversationId: conversationId,
      hasUnread: hasUnread ?? this.hasUnread,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
    );
  }

  factory FriendChatSummary.fromMap(String id, Map<String, dynamic> data) {
    return FriendChatSummary(
      friendUid: id,
      conversationId: data['conversationId'] as String? ?? id,
      hasUnread: data['hasUnread'] as bool? ?? false,
      lastMessage: data['lastMessage'] as String?,
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }
}
