import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a friend-to-friend conversation.
class Conversation {
  const Conversation({
    required this.id,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastReadAt,
  });

  final String id;
  final List<String> members;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LastMessage? lastMessage;
  final Map<String, DateTime>? lastReadAt; // uid -> when they last read

  /// Creates a Conversation from Firestore document
  factory Conversation.fromFirestore(String id, Map<String, dynamic> data) {
    // Parse lastReadAt map defensively – older documents may contain nulls
    // which would otherwise crash the cast to Timestamp.
    Map<String, DateTime>? lastReadAt;
    final rawLastReadAt = data['lastReadAt'];
    if (rawLastReadAt is Map<String, dynamic>) {
      final parsed = <String, DateTime>{};
      rawLastReadAt.forEach((key, value) {
        if (value is Timestamp) {
          parsed[key] = value.toDate();
        }
      });
      if (parsed.isNotEmpty) {
        lastReadAt = parsed;
      }
    }

    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];

    return Conversation(
      id: id,
      members: List<String>.from(data['members'] as List),
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: updatedAt is Timestamp
          ? updatedAt.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      lastMessage: data['lastMessage'] != null
          ? LastMessage.fromJson(
              data['lastMessage'] as Map<String, dynamic>,
            )
          : null,
      lastReadAt: lastReadAt,
    );
  }

  /// Converts to Firestore document data
  Map<String, dynamic> toFirestore() {
    // Convert lastReadAt map to Firestore timestamps
    Map<String, dynamic>? lastReadAtMap;
    if (lastReadAt != null) {
      lastReadAtMap = lastReadAt!.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      );
    }

    return {
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (lastMessage != null) 'lastMessage': lastMessage!.toJson(),
      if (lastReadAtMap != null) 'lastReadAt': lastReadAtMap,
    };
  }
}

/// Last message summary for conversation list display
class LastMessage {
  const LastMessage({
    required this.senderId,
    required this.preview,
    required this.createdAt,
    required this.type,
  });

  final String senderId;
  final String preview;
  final DateTime createdAt;
  final String type;

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    return LastMessage(
      senderId: json['senderId'] as String,
      preview: json['preview'] as String,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'preview': preview,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type,
    };
  }
}
