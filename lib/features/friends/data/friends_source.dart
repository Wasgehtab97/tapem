import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/friend.dart';
import '../domain/models/friend_request.dart';

class FriendsSource {
  FriendsSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const int _defaultFriendLimit = 150;
  static const int _defaultRequestLimit = 100;

  Future<List<Friend>> fetchFriends(
    String meUid, {
    int limit = _defaultFriendLimit,
  }) async {
    if (meUid.isEmpty) return const [];
    final snap = await _firestore
        .collection('users')
        .doc(meUid)
        .collection('friends')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => Friend.fromMap(d.id, d.data())).toList();
  }

  Future<List<FriendRequest>> fetchIncomingPending(
    String meUid, {
    int limit = _defaultRequestLimit,
  }) async {
    if (meUid.isEmpty) return const [];
    final snap = await _firestore
        .collection('friendRequests')
        .where('toUserId', isEqualTo: meUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => FriendRequest.fromMap(d.id, d.data()))
        .toList();
  }

  Future<List<FriendRequest>> fetchOutgoingPending(
    String meUid, {
    int limit = _defaultRequestLimit,
  }) async {
    if (meUid.isEmpty) return const [];
    final snap = await _firestore
        .collection('friendRequests')
        .where('fromUserId', isEqualTo: meUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => FriendRequest.fromMap(d.id, d.data()))
        .toList();
  }

  Future<List<FriendRequest>> fetchOutgoingAccepted(
    String meUid, {
    int limit = _defaultRequestLimit,
  }) async {
    if (meUid.isEmpty) return const [];
    final snap = await _firestore
        .collection('friendRequests')
        .where('fromUserId', isEqualTo: meUid)
        .where('status', isEqualTo: 'accepted')
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => FriendRequest.fromMap(d.id, d.data()))
        .toList();
  }
}
