import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/utils/friend_chat_id.dart';

/// API for friend-to-friend chat messaging.
///
/// **Security Model:**
/// - Requires friendship validation before sending messages
/// - Client-side validation via [isFriendCallback]
/// - Firestore security rules enforce conversation participant rules
///
/// **Error Handling:**
/// - Throws [FriendChatApiException] for all errors
/// - Common errors: [FriendChatApiError.permissionDenied] if not friends
class FriendChatApi {
  FriendChatApi({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required bool Function(String friendUid) isFriendCallback,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _isFriendCallback = isFriendCallback;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final bool Function(String friendUid) _isFriendCallback;

  /// Sends a message to a friend.
  ///
  /// Validates friendship before attempting to send. Creates the conversation
  /// if it doesn't exist yet (first message).
  ///
  /// Throws [FriendChatApiException] if:
  /// - User is not authenticated ([FriendChatApiError.unauthenticated])
  /// - [friendUid] is not in the user's friends list ([FriendChatApiError.permissionDenied])
  /// - [text] is empty ([FriendChatApiError.invalidArgument])
  /// - [friendUid] is the same as current user ([FriendChatApiError.invalidArgument])
  Future<void> sendMessage(String friendUid, String text) async {
    final meUid = _auth.currentUser?.uid;
    if (meUid == null) {
      throw FriendChatApiException(FriendChatApiError.unauthenticated);
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw FriendChatApiException(FriendChatApiError.invalidArgument);
    }
    if (friendUid == meUid) {
      throw FriendChatApiException(FriendChatApiError.invalidArgument);
    }

    // Validate friendship before attempting to send
    final isFriend = _isFriendCallback(friendUid);
    if (kDebugMode) {
      debugPrint(
        '[FriendChatApi] friendship check: friendUid=$friendUid isFriend=$isFriend',
      );
    }
    if (!isFriend) {
      if (kDebugMode) {
        debugPrint(
          '[FriendChatApi] sendMessage rejected: $friendUid is not a friend of $meUid',
        );
      }
      throw FriendChatApiException(
        FriendChatApiError.permissionDenied,
        'Can only send messages to friends',
      );
    }

    final conversationId = buildFriendChatId(meUid, friendUid);
    final conversationRef =
        _firestore.collection('friendConversations').doc(conversationId);
    final members = [meUid, friendUid]..sort();

    if (kDebugMode) {
      final preview = trimmed.length > 120 ? '${trimmed.substring(0, 120)}…' : trimmed;
      debugPrint(
        '[FriendChatApi] send start me=$meUid friend=$friendUid conversation=$conversationId '
        'len=${trimmed.length} preview="$preview"',
      );
    }

    try {
      final messageRef = conversationRef.collection('messages').doc();
      final messageId = messageRef.id;
      await _firestore.runTransaction((txn) async {
        final snapshot = await txn.get(conversationRef);
        final timestamp = FieldValue.serverTimestamp();

        if (!snapshot.exists) {
          txn.set(conversationRef, {
            'members': members,
            'updatedAt': timestamp,
          });
        } else {
          final data = snapshot.data();
          final existingMembers = data?['members'];
          if (existingMembers is! List ||
              !existingMembers.contains(meUid) ||
              !existingMembers.contains(friendUid)) {
            throw FriendChatApiException(FriendChatApiError.permissionDenied);
          }
        }

        txn.set(messageRef, {
          'senderId': meUid,
          'text': trimmed,
          'createdAt': timestamp,
        });

        txn.update(conversationRef, {
          'lastMessage': trimmed,
          'lastMessageAt': timestamp,
          'lastMessageSenderId': meUid,
          'updatedAt': timestamp,
        });

        final mySummary = _firestore
            .collection('users')
            .doc(meUid)
            .collection('friendChats')
            .doc(friendUid);
        txn.set(mySummary, {
          'conversationId': conversationId,
          'hasUnread': false,
          'lastMessage': trimmed,
          'lastMessageAt': timestamp,
          'lastMessageSenderId': meUid,
          'updatedAt': timestamp,
        }, SetOptions(merge: true));

        final friendSummary = _firestore
            .collection('users')
            .doc(friendUid)
            .collection('friendChats')
            .doc(meUid);
        txn.set(friendSummary, {
          'conversationId': conversationId,
          'hasUnread': true,
          'lastMessage': trimmed,
          'lastMessageAt': timestamp,
          'lastMessageSenderId': meUid,
          'updatedAt': timestamp,
        }, SetOptions(merge: true));
      });
      if (kDebugMode) {
        debugPrint(
          '[FriendChatApi] send success me=$meUid friend=$friendUid conversation=$conversationId '
          'messageId=$messageId',
        );
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[FriendChatApi] send firebase error code=${e.code} message=${e.message}');
      }
      throw FriendChatApiException.fromCode(e.code, e.message);
    } on FriendChatApiException {
      rethrow;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FriendChatApi] send unexpected error: $e');
        debugPrintStack(stackTrace: st);
      }
      throw FriendChatApiException(FriendChatApiError.unknown);
    }
  }

  /// Marks a conversation as read.
  ///
  /// Updates the user's chat summary to indicate all messages have been read.
  ///
  /// Throws [FriendChatApiException] if user is not authenticated.
  Future<void> markConversationRead(String friendUid) async {
    final meUid = _auth.currentUser?.uid;
    if (meUid == null) {
      throw FriendChatApiException(FriendChatApiError.unauthenticated);
    }
    final summaryRef = _firestore
        .collection('users')
        .doc(meUid)
        .collection('friendChats')
        .doc(friendUid);
    try {
      if (kDebugMode) {
        debugPrint('[FriendChatApi] markRead me=$meUid friend=$friendUid');
      }
      await summaryRef.set({
        'hasUnread': false,
        'lastReadAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[FriendChatApi] markRead firebase error code=${e.code} message=${e.message}');
      }
      throw FriendChatApiException.fromCode(e.code, e.message);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FriendChatApi] markRead unexpected error: $e');
        debugPrintStack(stackTrace: st);
      }
      throw FriendChatApiException(FriendChatApiError.unknown);
    }
  }
}

enum FriendChatApiError {
  unauthenticated,
  invalidArgument,
  permissionDenied,
  notFound,
  unknown,
}

class FriendChatApiException implements Exception {
  FriendChatApiException(this.code, [this.message]);

  final FriendChatApiError code;
  final String? message;

  factory FriendChatApiException.fromCode(String code, String? message) {
    switch (code) {
      case 'permission-denied':
        return FriendChatApiException(
            FriendChatApiError.permissionDenied, message);
      case 'not-found':
        return FriendChatApiException(FriendChatApiError.notFound, message);
      case 'unauthenticated':
        return FriendChatApiException(
            FriendChatApiError.unauthenticated, message);
      case 'invalid-argument':
        return FriendChatApiException(
            FriendChatApiError.invalidArgument, message);
      default:
        return FriendChatApiException(FriendChatApiError.unknown, message);
    }
  }

  @override
  String toString() => 'FriendChatApiException($code, $message)';
}
