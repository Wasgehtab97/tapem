import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an encrypted conversation key stored in Firestore.
/// Each participant has their own copy of the key, encrypted with their public key.
class ConversationKey {
  const ConversationKey({
    required this.conversationId,
    required this.userId,
    required this.encryptedKey,
    required this.createdAt,
  });

  final String conversationId;
  final String userId;
  /// The conversation's symmetric key, encrypted with this user's public key
  final String encryptedKey; // Base64 encoded
  final DateTime createdAt;

  /// Creates a ConversationKey from Firestore document
  factory ConversationKey.fromFirestore(Map<String, dynamic> data) {
    return ConversationKey(
      conversationId: data['conversationId'] as String,
      userId: data['userId'] as String,
      encryptedKey: data['encryptedKey'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Converts to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'userId': userId,
      'encryptedKey': encryptedKey,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
