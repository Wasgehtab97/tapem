import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/chat_message.dart';
import '../../domain/models/conversation.dart';
import '../../domain/utils/friend_chat_id.dart';

/// Repository for friend chat operations with Firestore.
///
/// Handles all database interactions for conversations and messages.
class ChatRepository {
  ChatRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Watches messages in a conversation in real-time.
  ///
  /// Messages are ordered by creation time (oldest first).
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    if (kDebugMode) {
      debugPrint('[ChatRepository] watchMessages conversationId=$conversationId');
    }

    return _firestore
        .collection('friendConversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      if (kDebugMode) {
        debugPrint(
          '[ChatRepository] watchMessages snapshot count=${snapshot.docs.length}',
        );
      }
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  /// Watches a specific conversation in real-time.
  Stream<Conversation?> watchConversation(String conversationId) {
    if (kDebugMode) {
      debugPrint(
        '[ChatRepository] watchConversation conversationId=$conversationId',
      );
    }

    return _firestore
        .collection('friendConversations')
        .doc(conversationId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        if (kDebugMode) {
          debugPrint('[ChatRepository] conversation does not exist');
        }
        return null;
      }
      return Conversation.fromFirestore(doc.id, doc.data()!);
    });
  }

  /// Sends a text message in a conversation.
  ///
  /// Creates the conversation if it doesn't exist yet.
  /// Updates the conversation's lastMessage field.
  Future<void> sendTextMessage({
    required String currentUserId,
    required String friendUid,
    required String text,
    bool isEncrypted = false,
    String? nonce,
  }) async {
    final conversationId = buildFriendChatId(currentUserId, friendUid);
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      throw ArgumentError('Message text cannot be empty');
    }

    if (kDebugMode) {
      debugPrint(
        '[ChatRepository] sendTextMessage conversationId=$conversationId text="${trimmed.substring(0, trimmed.length > 20 ? 20 : trimmed.length)}..."',
      );
    }

    final conversationRef =
        _firestore.collection('friendConversations').doc(conversationId);
    final messagesRef = conversationRef.collection('messages');

    final now = DateTime.now();
    final message = ChatMessage(
      id: '', // Will be set by Firestore
      senderId: currentUserId,
      type: MessageType.text,
      createdAt: now,
      text: trimmed,
      isEncrypted: isEncrypted,
      nonce: nonce,
    );

    final lastMessage = LastMessage(
      senderId: currentUserId,
      preview: trimmed.length > 100 ? '${trimmed.substring(0, 100)}...' : trimmed,
      createdAt: now,
      type: 'text',
    );

    try {
      await _firestore.runTransaction((transaction) async {
        // Check if conversation exists
        final conversationDoc = await transaction.get(conversationRef);

        if (!conversationDoc.exists) {
          // Create new conversation
          final conversation = Conversation(
            id: conversationId,
            members: [currentUserId, friendUid]..sort(),
            createdAt: now,
            updatedAt: now,
            lastMessage: lastMessage,
          );
          transaction.set(conversationRef, conversation.toFirestore());
          if (kDebugMode) {
            debugPrint('[ChatRepository] created new conversation');
          }
        } else {
          // Update existing conversation
          transaction.update(conversationRef, {
            'updatedAt': Timestamp.fromDate(now),
            'lastMessage': lastMessage.toJson(),
          });
          if (kDebugMode) {
            debugPrint('[ChatRepository] updated existing conversation');
          }
        }

        // Add message
        final messageDoc = messagesRef.doc();
        transaction.set(messageDoc, message.toFirestore());
        if (kDebugMode) {
          debugPrint('[ChatRepository] added message id=${messageDoc.id}');
        }
      });

      if (kDebugMode) {
        debugPrint('[ChatRepository] sendTextMessage success');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[ChatRepository] sendTextMessage error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Sends a sticker message in a conversation.
  Future<void> sendStickerMessage({
    required String currentUserId,
    required String friendUid,
    required String stickerId,
  }) async {
    final conversationId = buildFriendChatId(currentUserId, friendUid);

    if (kDebugMode) {
      debugPrint(
        '[ChatRepository] sendStickerMessage conversationId=$conversationId stickerId=$stickerId',
      );
    }

    final conversationRef =
        _firestore.collection('friendConversations').doc(conversationId);
    final messagesRef = conversationRef.collection('messages');

    final now = DateTime.now();
    final message = ChatMessage(
      id: '', // Will be set by Firestore
      senderId: currentUserId,
      type: MessageType.sticker,
      createdAt: now,
      stickerId: stickerId,
    );

    final lastMessage = LastMessage(
      senderId: currentUserId,
      preview: 'Sticker',
      createdAt: now,
      type: 'sticker',
    );

    try {
      await _firestore.runTransaction((transaction) async {
        // Check if conversation exists
        final conversationDoc = await transaction.get(conversationRef);

        if (!conversationDoc.exists) {
          // Create new conversation
          final conversation = Conversation(
            id: conversationId,
            members: [currentUserId, friendUid]..sort(),
            createdAt: now,
            updatedAt: now,
            lastMessage: lastMessage,
          );
          transaction.set(conversationRef, conversation.toFirestore());
        } else {
          // Update existing conversation
          transaction.update(conversationRef, {
            'updatedAt': Timestamp.fromDate(now),
            'lastMessage': lastMessage.toJson(),
          });
        }

        // Add message
        final messageDoc = messagesRef.doc();
        transaction.set(messageDoc, message.toFirestore());
      });

      if (kDebugMode) {
        debugPrint('[ChatRepository] sendStickerMessage success');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ChatRepository] sendStickerMessage error: $e');
      }
      rethrow;
    }
  }

  /// Marks a conversation as read by updating the lastReadAt timestamp.
  ///
  /// This is used to track which messages the user has seen.
  Future<void> markAsRead({
    required String currentUserId,
    required String conversationId,
  }) async {
    final conversationRef =
        _firestore.collection('friendConversations').doc(conversationId);

    try {
      await conversationRef.update({
        'lastReadAt.$currentUserId': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Gets the conversation ID for a friend chat.
  String getConversationId(String currentUserId, String friendUid) {
    return buildFriendChatId(currentUserId, friendUid);
  }
}
