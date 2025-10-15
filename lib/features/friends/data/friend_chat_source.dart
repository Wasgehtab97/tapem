import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/friend_chat_summary.dart';
import '../domain/models/friend_message.dart';
import '../domain/utils/friend_chat_id.dart';

class FriendChatSource {
  FriendChatSource(this._firestore);

  final FirebaseFirestore _firestore;

  final Duration _cacheTtl = const Duration(minutes: 2);

  final Map<String, _CachedSummaries> _summaryCache =
      <String, _CachedSummaries>{};
  final Map<String, _CachedConversation> _conversationCache =
      <String, _CachedConversation>{};

  Future<List<FriendChatSummary>> fetchSummaries(
    String meUid, {
    bool forceRefresh = false,
    int limit = 50,
  }) async {
    if (meUid.isEmpty) return const [];
    if (!forceRefresh) {
      final cached = _summaryCache[meUid];
      if (cached != null && _isFresh(cached.timestamp)) {
        return cached.summaries;
      }
    }
    final queryLimit = _normalizeLimit(limit);
    final query = _firestore
        .collection('users')
        .doc(meUid)
        .collection('friendChats')
        .orderBy('lastMessageAt', descending: true)
        .limit(queryLimit);
    final snap = await query.get();
    final summaries =
        snap.docs.map((d) => FriendChatSummary.fromMap(d.id, d.data())).toList();
    _summaryCache[meUid] =
        _CachedSummaries(summaries: summaries, timestamp: DateTime.now());
    return summaries;
  }

  List<FriendChatSummary> getCachedSummaries(String meUid) {
    final cached = _summaryCache[meUid];
    if (cached == null || !_isFresh(cached.timestamp)) {
      return const [];
    }
    return cached.summaries;
  }

  Future<FriendChatMessagesSnapshot> fetchMessages(
    String meUid,
    String friendUid, {
    bool forceRefresh = false,
    int limit = 50,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    if (meUid.isEmpty || friendUid.isEmpty) {
      return FriendChatMessagesSnapshot.empty();
    }

    final normalizedLimit = _normalizeLimit(limit);
    final conversationId = buildFriendChatId(meUid, friendUid);
    final cacheKey = conversationId;
    final cached = _conversationCache[cacheKey];
    if (!forceRefresh && startAfter == null) {
      if (cached != null && _isFresh(cached.timestamp)) {
        return cached.snapshot;
      }
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('friendConversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(normalizedLimit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    final docs = snap.docs;
    final fetched = docs
        .map((d) => FriendMessage.fromMap(d.id, d.data()))
        .toList()
        .reversed
        .toList();
    final hasMore = docs.length == normalizedLimit;
    final lastDoc = docs.isNotEmpty ? docs.last : cached?.snapshot.lastDocument;

    List<FriendMessage> merged;
    if (startAfter == null || forceRefresh || cached == null) {
      merged = fetched;
    } else {
      final seen = <String>{};
      merged = <FriendMessage>[];
      for (final msg in fetched) {
        if (seen.add(msg.id)) {
          merged.add(msg);
        }
      }
      for (final msg in cached.snapshot.messages) {
        if (seen.add(msg.id)) {
          merged.add(msg);
        }
      }
    }

    final snapshotResult = FriendChatMessagesSnapshot(
      messages: merged,
      hasMore: hasMore,
      lastDocument: lastDoc,
    );
    _conversationCache[cacheKey] =
        _CachedConversation(snapshot: snapshotResult, timestamp: DateTime.now());
    return snapshotResult;
  }

  FriendChatMessagesSnapshot getCachedMessages(
    String meUid,
    String friendUid,
  ) {
    final cache = _conversationCache[buildFriendChatId(meUid, friendUid)];
    if (cache == null || !_isFresh(cache.timestamp)) {
      return FriendChatMessagesSnapshot.empty();
    }
    return cache.snapshot;
  }

  void clearSummaries(String meUid) {
    _summaryCache.remove(meUid);
  }

  void clearConversation(String meUid, String friendUid) {
    _conversationCache.remove(buildFriendChatId(meUid, friendUid));
  }

  void clearAll() {
    _summaryCache.clear();
    _conversationCache.clear();
  }

  bool _isFresh(DateTime timestamp) {
    return DateTime.now().difference(timestamp) < _cacheTtl;
  }

  int _normalizeLimit(int limit) {
    if (limit < 1) return 1;
    if (limit > 50) return 50;
    return limit;
  }
}

class FriendChatMessagesSnapshot {
  FriendChatMessagesSnapshot({
    required this.messages,
    required this.hasMore,
    this.lastDocument,
  });

  final List<FriendMessage> messages;
  final bool hasMore;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;

  factory FriendChatMessagesSnapshot.empty() {
    return FriendChatMessagesSnapshot(
      messages: const <FriendMessage>[],
      hasMore: false,
    );
  }
}

class _CachedSummaries {
  _CachedSummaries({required this.summaries, required this.timestamp});

  final List<FriendChatSummary> summaries;
  final DateTime timestamp;
}

class _CachedConversation {
  _CachedConversation({required this.snapshot, required this.timestamp});

  final FriendChatMessagesSnapshot snapshot;
  final DateTime timestamp;
}
