import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/utils/friend_chat_id.dart';

class FriendChatApi {
  FriendChatApi({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

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

    final conversationId = buildFriendChatId(meUid, friendUid);
    final conversationRef =
        _firestore.collection('friendConversations').doc(conversationId);
    final members = [meUid, friendUid]..sort();

    try {
      await conversationRef.set({'members': members}, SetOptions(merge: true));
      await _firestore.runTransaction((txn) async {
        final timestamp = FieldValue.serverTimestamp();
        final messageRef =
            conversationRef.collection('messages').doc();
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
    } on FirebaseException catch (e) {
      throw FriendChatApiException.fromCode(e.code, e.message);
    } catch (_) {
      throw FriendChatApiException(FriendChatApiError.unknown);
    }
  }

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
      await summaryRef.set({
        'hasUnread': false,
        'lastReadAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw FriendChatApiException.fromCode(e.code, e.message);
    } catch (_) {
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
