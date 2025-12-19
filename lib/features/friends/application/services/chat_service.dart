import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/models/chat_message.dart';
import '../../domain/models/conversation.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../security/domain/services/encryption_service.dart';
import '../../../../core/data/user_profile_service.dart';
import './conversation_key_service.dart';

/// Service for friend chat business logic.
///
/// Handles validation and orchestrates repository calls.
class ChatService {
  ChatService({
    required ChatRepository repository,
    required FirebaseAuth auth,
    required bool Function(String friendUid) isFriendCallback,
    required EncryptionService encryptionService,
    required ConversationKeyService conversationKeyService,
  })  : _repository = repository,
        _auth = auth,
        _isFriendCallback = isFriendCallback,
        _encryptionService = encryptionService,
        _conversationKeyService = conversationKeyService;

  final ChatRepository _repository;
  final FirebaseAuth _auth;
  final bool Function(String friendUid) _isFriendCallback;
  final EncryptionService _encryptionService;
  final ConversationKeyService _conversationKeyService;
  static const bool _logChat = false;

  ChatMessage _redactEncryptedMessage(ChatMessage msg) {
    return ChatMessage(
      id: msg.id,
      senderId: msg.senderId,
      type: msg.type,
      createdAt: msg.createdAt,
      text: msg.type == MessageType.text ? 'Verschluesselte Nachricht' : msg.text,
      highlightData: msg.highlightData,
      isEncrypted: true,
      nonce: msg.nonce,
      stickerId: msg.stickerId,
    );
  }

  /// Gets the current user ID.
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Watches messages for a friend chat.
  ///
  /// Returns a stream that emits the list of messages whenever they change.
  Stream<List<ChatMessage>> watchMessages(String friendUid) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      if (kDebugMode && _logChat) {
        debugPrint('[ChatService] watchMessages: user not authenticated');
      }
      return Stream.value([]);
    }

    final conversationId = _repository.getConversationId(currentUserId, friendUid);

    return _repository.watchMessages(conversationId).asyncMap((messages) async {
      // Get conversation key for decryption
      final conversationKey = await _conversationKeyService.getConversationKey(
        conversationId: conversationId,
        userId: currentUserId,
      );

      if (conversationKey == null) {
        // No encryption key yet (might be first message)
        return messages
            .map((msg) => msg.isEncrypted ? _redactEncryptedMessage(msg) : msg)
            .toList();
      }

      // Decrypt encrypted messages
      return Future.wait(messages.map((msg) async {
        if (msg.isEncrypted && msg.nonce != null && msg.text != null) {
          try {
            final decryptedText = await _encryptionService.decryptMessageWithKey(
              msg.text!,
              msg.nonce!,
              conversationKey,
            );

            return ChatMessage(
              id: msg.id,
              senderId: msg.senderId,
              type: msg.type,
              createdAt: msg.createdAt,
              text: decryptedText,
              highlightData: msg.highlightData,
              isEncrypted: false, // Mark as decrypted for UI
              nonce: msg.nonce,
            );
          } catch (e) {
            if (kDebugMode && _logChat) {
              debugPrint('[ChatService] Decryption failed for msg ${msg.id}: $e');
            }
            return _redactEncryptedMessage(msg);
          }
        }
        return msg;
      }));
    });
  }

  /// Watches the conversation metadata for a friend chat.
  Stream<Conversation?> watchConversation(String friendUid) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      if (kDebugMode && _logChat) {
        debugPrint('[ChatService] watchConversation: user not authenticated');
      }
      return Stream.value(null);
    }

    final conversationId = _repository.getConversationId(currentUserId, friendUid);
    return _repository.watchConversation(conversationId);
  }

  /// Sends a text message to a friend.
  ///
  /// Validates:
  /// - User is authenticated
  /// - Recipient is a friend
  /// - Message is not empty
  ///
  /// Throws:
  /// - [StateError] if user is not authenticated
  /// - [ArgumentError] if recipient is not a friend or message is empty
  Future<void> sendTextMessage({
    required String friendUid,
    required String text,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw StateError('User must be authenticated to send messages');
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Message text cannot be empty');
    }

    if (friendUid == currentUserId) {
      throw ArgumentError('Cannot send message to yourself');
    }

    // Validate friendship
    if (!_isFriendCallback(friendUid)) {
      if (kDebugMode && _logChat) {
        debugPrint(
          '[ChatService] sendTextMessage rejected: $friendUid is not a friend',
        );
      }
      throw ArgumentError('Can only send messages to friends');
    }

    if (kDebugMode && _logChat) {
      debugPrint(
        '[ChatService] sendTextMessage: friendUid=$friendUid textLength=${trimmed.length}',
      );
    }

    final conversationId = _repository.getConversationId(currentUserId, friendUid);

    // Get or create conversation key
    var conversationKey = await _conversationKeyService.getConversationKey(
      conversationId: conversationId,
      userId: currentUserId,
    );

    if (conversationKey == null) {
      // First message - create conversation key
      if (kDebugMode && _logChat) {
        debugPrint('[ChatService] Creating new conversation key');
      }

      await _conversationKeyService.initializeConversationKey(
        conversationId: conversationId,
        creatorId: currentUserId,
        userAId: currentUserId,
        userBId: friendUid,
      );

      // Retrieve the newly created key
      conversationKey = await _conversationKeyService.getConversationKey(
        conversationId: conversationId,
        userId: currentUserId,
      );

      if (conversationKey == null) {
        throw Exception('Failed to create conversation key');
      }
    }

    // Encrypt message
    final encrypted = await _encryptionService.encryptMessageWithKey(
      trimmed,
      conversationKey,
    );

    await _repository.sendTextMessage(
      currentUserId: currentUserId,
      friendUid: friendUid,
      text: encrypted['content']!,
      isEncrypted: true,
      nonce: encrypted['nonce'],
    );

    if (kDebugMode && _logChat) {
      debugPrint('[ChatService] sendTextMessage: success (encrypted=true)');
    }
  }

  /// Sends a sticker message to a friend.
  Future<void> sendStickerMessage({
    required String friendUid,
    required String stickerId,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw StateError('User must be authenticated to send messages');
    }

    if (friendUid == currentUserId) {
      throw ArgumentError('Cannot send message to yourself');
    }

    // Validate friendship
    if (!_isFriendCallback(friendUid)) {
      throw ArgumentError('Can only send messages to friends');
    }

    await _repository.sendStickerMessage(
      currentUserId: currentUserId,
      friendUid: friendUid,
      stickerId: stickerId,
    );
  }
}
