import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/friend_chat_summary.dart';
import '../domain/models/friend_message.dart';
import '../domain/utils/friend_chat_id.dart';

class FriendChatSource {
  FriendChatSource(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<FriendChatSummary>> watchSummaries(String meUid) {
    return _firestore
        .collection('users')
        .doc(meUid)
        .collection('friendChats')
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FriendChatSummary.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<FriendMessage>> watchMessages(String meUid, String friendUid,
      {int limit = 200}) {
    final conversationId = buildFriendChatId(meUid, friendUid);
    return _firestore
        .collection('friendConversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FriendMessage.fromMap(d.id, d.data()))
            .toList()
            .reversed
            .toList());
  }
}
