import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a message in a friend chat conversation.
///
/// Supports different message types:
/// - Text messages
/// - Session highlight shares (future)
/// - Images/media (future)
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.type,
    required this.createdAt,
    this.text,
    this.highlightData,
    this.isEncrypted = false,
    this.nonce,
    this.stickerId,
  });

  final String id;
  final String senderId;
  final MessageType type;
  final DateTime createdAt;
  final String? text;
  final HighlightData? highlightData;
  final bool isEncrypted;
  final String? nonce;
  final String? stickerId;

  /// Creates a ChatMessage from Firestore document
  factory ChatMessage.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      senderId: data['senderId'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      text: data['text'] as String?,
      highlightData: data['highlightData'] != null
          ? HighlightData.fromJson(
              data['highlightData'] as Map<String, dynamic>,
            )
          : null,
      isEncrypted: data['isEncrypted'] as bool? ?? false,
      nonce: data['nonce'] as String?,
      stickerId: data['stickerId'] as String?,
    );
  }

  /// Converts to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      if (text != null) 'text': text,
      if (highlightData != null) 'highlightData': highlightData!.toJson(),
      'isEncrypted': isEncrypted,
      if (nonce != null) 'nonce': nonce,
      if (stickerId != null) 'stickerId': stickerId,
    };
  }
}

/// Message type enum
enum MessageType {
  text,
  highlight,
  image,
  sticker,
}

/// Data for session highlight messages (future use)
class HighlightData {
  const HighlightData({
    required this.sessionId,
    required this.exerciseName,
    required this.achievement,
    this.imageUrl,
  });

  final String sessionId;
  final String exerciseName;
  final String achievement;
  final String? imageUrl;

  factory HighlightData.fromJson(Map<String, dynamic> json) {
    return HighlightData(
      sessionId: json['sessionId'] as String,
      exerciseName: json['exerciseName'] as String,
      achievement: json['achievement'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'exerciseName': exerciseName,
      'achievement': achievement,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
