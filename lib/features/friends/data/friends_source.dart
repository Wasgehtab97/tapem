import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/friend.dart';
import '../domain/models/friend_request.dart';

class FriendsSource {
  FriendsSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const int _pageSize = 50;
  final Duration _cacheTtl = const Duration(minutes: 2);

  final Map<String, _CachedPage<Friend>> _friendsCache =
      <String, _CachedPage<Friend>>{};
  final Map<String, _CachedPage<FriendRequest>> _incomingCache =
      <String, _CachedPage<FriendRequest>>{};
  final Map<String, _CachedPage<FriendRequest>> _outgoingCache =
      <String, _CachedPage<FriendRequest>>{};
  final Map<String, _CachedPage<FriendRequest>> _acceptedCache =
      <String, _CachedPage<FriendRequest>>{};

  Future<PaginatedResult<Friend>> fetchFriends(
    String meUid, {
    int limit = _pageSize,
    bool forceRefresh = false,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    if (meUid.isEmpty) {
      return PaginatedResult<Friend>.empty();
    }
    final normalizedLimit = _normalizeLimit(limit);
    if (!forceRefresh && startAfter == null) {
      final cached = _friendsCache[meUid];
      if (cached != null && _isFresh(cached.timestamp)) {
        return cached.page;
      }
    }

    var query = _firestore
        .collection('users')
        .doc(meUid)
        .collection('friends')
        .orderBy('createdAt', descending: true);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.limit(normalizedLimit).get();
    final items = snap.docs.map((d) => Friend.fromMap(d.id, d.data())).toList();
    final result = PaginatedResult<Friend>(
      items: items,
      hasMore: snap.docs.length == normalizedLimit,
      lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
    if (startAfter == null) {
      _friendsCache[meUid] = _CachedPage(result, DateTime.now());
    }
    return result;
  }

  Future<PaginatedResult<FriendRequest>> fetchIncomingPending(
    String meUid, {
    int limit = _pageSize,
    bool forceRefresh = false,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    if (meUid.isEmpty) {
      return PaginatedResult<FriendRequest>.empty();
    }
    final normalizedLimit = _normalizeLimit(limit);
    if (!forceRefresh && startAfter == null) {
      final cached = _incomingCache[meUid];
      if (cached != null && _isFresh(cached.timestamp)) {
        return cached.page;
      }
    }

    var query = _firestore
        .collection('friendRequests')
        .where('toUserId', isEqualTo: meUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.limit(normalizedLimit).get();
    final items =
        snap.docs.map((d) => FriendRequest.fromMap(d.id, d.data())).toList();
    final result = PaginatedResult<FriendRequest>(
      items: items,
      hasMore: snap.docs.length == normalizedLimit,
      lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
    if (startAfter == null) {
      _incomingCache[meUid] = _CachedPage(result, DateTime.now());
    }
    return result;
  }

  Future<PaginatedResult<FriendRequest>> fetchOutgoingPending(
    String meUid, {
    int limit = _pageSize,
    bool forceRefresh = false,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    if (meUid.isEmpty) {
      return PaginatedResult<FriendRequest>.empty();
    }
    final normalizedLimit = _normalizeLimit(limit);
    if (!forceRefresh && startAfter == null) {
      final cached = _outgoingCache[meUid];
      if (cached != null && _isFresh(cached.timestamp)) {
        return cached.page;
      }
    }

    var query = _firestore
        .collection('friendRequests')
        .where('fromUserId', isEqualTo: meUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.limit(normalizedLimit).get();
    final items =
        snap.docs.map((d) => FriendRequest.fromMap(d.id, d.data())).toList();
    final result = PaginatedResult<FriendRequest>(
      items: items,
      hasMore: snap.docs.length == normalizedLimit,
      lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
    if (startAfter == null) {
      _outgoingCache[meUid] = _CachedPage(result, DateTime.now());
    }
    return result;
  }

  Future<PaginatedResult<FriendRequest>> fetchOutgoingAccepted(
    String meUid, {
    int limit = _pageSize,
    bool forceRefresh = false,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    if (meUid.isEmpty) {
      return PaginatedResult<FriendRequest>.empty();
    }
    final normalizedLimit = _normalizeLimit(limit);
    if (!forceRefresh && startAfter == null) {
      final cached = _acceptedCache[meUid];
      if (cached != null && _isFresh(cached.timestamp)) {
        return cached.page;
      }
    }

    var query = _firestore
        .collection('friendRequests')
        .where('fromUserId', isEqualTo: meUid)
        .where('status', isEqualTo: 'accepted')
        .orderBy('updatedAt', descending: true);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.limit(normalizedLimit).get();
    final items =
        snap.docs.map((d) => FriendRequest.fromMap(d.id, d.data())).toList();
    final result = PaginatedResult<FriendRequest>(
      items: items,
      hasMore: snap.docs.length == normalizedLimit,
      lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
    if (startAfter == null) {
      _acceptedCache[meUid] = _CachedPage(result, DateTime.now());
    }
    return result;
  }

  void clearUserCache(String meUid) {
    _friendsCache.remove(meUid);
    _incomingCache.remove(meUid);
    _outgoingCache.remove(meUid);
    _acceptedCache.remove(meUid);
  }

  void clearAll() {
    _friendsCache.clear();
    _incomingCache.clear();
    _outgoingCache.clear();
    _acceptedCache.clear();
  }

  bool _isFresh(DateTime timestamp) {
    return DateTime.now().difference(timestamp) < _cacheTtl;
  }

  int _normalizeLimit(int limit) {
    if (limit < 1) return 1;
    if (limit > _pageSize) return _pageSize;
    return limit;
  }
}

class PaginatedResult<T> {
  PaginatedResult({
    required this.items,
    required this.hasMore,
    this.lastDocument,
  });

  final List<T> items;
  final bool hasMore;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;

  factory PaginatedResult.empty() {
    return PaginatedResult<T>(
      items: List<T>.unmodifiable(<T>[]),
      hasMore: false,
    );
  }
}

class _CachedPage<T> {
  _CachedPage(this.page, this.timestamp);

  final PaginatedResult<T> page;
  final DateTime timestamp;
}
