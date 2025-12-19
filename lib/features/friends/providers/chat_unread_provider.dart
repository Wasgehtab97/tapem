import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/firebase_provider.dart';
import '../domain/models/conversation.dart';

/// State holding unread message counts.
class ChatUnreadState {
  const ChatUnreadState({
    this.unreadByFriend = const {},
    this.totalUnread = 0,
  });

  final Map<String, int> unreadByFriend; // friendUid -> count
  final int totalUnread;

  bool get hasUnread => totalUnread > 0;

  ChatUnreadState copyWith({
    Map<String, int>? unreadByFriend,
    int? totalUnread,
  }) {
    return ChatUnreadState(
      unreadByFriend: unreadByFriend ?? this.unreadByFriend,
      totalUnread: totalUnread ?? this.totalUnread,
    );
  }
}

/// Provider that watches all conversations and calculates unread counts.
class ChatUnreadNotifier extends StreamNotifier<ChatUnreadState> {
  /// Allows marking a conversation with [friendUid] as read on the client.
  ///
  /// This updates the local unread state immediately (for responsive UI),
  /// while the Firestore-backed stream will keep things consistent once
  /// `lastReadAt` has been written by the chat screen.
  void markFriendAsRead(String friendUid) {
    final currentValue = state.value ?? const ChatUnreadState();
    if (!currentValue.unreadByFriend.containsKey(friendUid)) {
      return;
    }
    final updated = Map<String, int>.from(currentValue.unreadByFriend)
      ..remove(friendUid);
    final newTotal =
        updated.values.fold<int>(0, (total, value) => total + value);
    final updatedState = currentValue.copyWith(
      unreadByFriend: updated,
      totalUnread: newTotal,
    );
    state = AsyncValue.data(updatedState);
  }

  @override
  Stream<ChatUnreadState> build() {
    final firestore = ref.watch(firebaseFirestoreProvider);
    final authState = ref.watch(authViewStateProvider);
    final currentUserId = authState.userId;

    if (currentUserId == null) {
      return Stream.value(const ChatUnreadState());
    }

    // Watch all conversations where user is a member
    return firestore
        .collection('friendConversations')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final unreadByFriend = <String, int>{};
      int totalUnread = 0;

      for (final doc in snapshot.docs) {
        try {
          final conversation = Conversation.fromFirestore(doc.id, doc.data());
          
          // Find the friend UID (the other member)
          final friendUid = conversation.members.firstWhere(
            (uid) => uid != currentUserId,
            orElse: () => '',
          );

          if (friendUid.isEmpty) continue;

          // Get when current user last read this conversation
          final lastReadAt = conversation.lastReadAt?[currentUserId];
          
          // Get last message info
          final lastMessage = conversation.lastMessage;
          final lastMessageAt = lastMessage?.createdAt;
          final lastSenderId = lastMessage?.senderId;

          // If there's a last message 
          // AND it's NOT from me (important!)
          // AND I haven't read it yet (or never read)
          if (lastMessageAt != null &&
              lastSenderId != currentUserId &&
              (lastReadAt == null || lastMessageAt.isAfter(lastReadAt))) {
            // For now, just count as 1 unread (we could fetch actual count later)
            unreadByFriend[friendUid] = 1;
            totalUnread += 1;
          }
        } catch (_) {}
      }

      return ChatUnreadState(
        unreadByFriend: unreadByFriend,
        totalUnread: totalUnread,
      );
    });
  }
}

/// Provider for chat unread state
final chatUnreadProvider =
    StreamNotifierProvider<ChatUnreadNotifier, ChatUnreadState>(
  ChatUnreadNotifier.new,
);
