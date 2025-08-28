import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/friend.dart';
import '../domain/models/friend_request.dart';

class FriendsSource {
  FriendsSource(this._firestore);
  final FirebaseFirestore _firestore;

  Stream<List<Friend>> watchFriends(String meUid) {
    return _firestore
        .collection('users')
        .doc(meUid)
        .collection('friends')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Friend.fromMap(d.id, d.data())).toList());
  }

  Stream<List<FriendRequest>> watchIncoming(String meUid) {
    return _firestore
        .collection('friendRequests')
        .where('toUserId', isEqualTo: meUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FriendRequest.fromMap(d.id, d.data())).toList());
  }

  Stream<List<FriendRequest>> watchOutgoing(String meUid) {
    return _firestore
        .collection('friendRequests')
        .where('fromUserId', isEqualTo: meUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FriendRequest.fromMap(d.id, d.data())).toList());
  }

  Stream<List<FriendRequest>> watchOutgoingAccepted(String meUid) {
    return _firestore
        .collection('friendRequests')
        .where('fromUserId', isEqualTo: meUid)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FriendRequest.fromMap(d.id, d.data())).toList());
  }
}
