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
        .orderBy('since', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Friend.fromMap(d.id, d.data())).toList());
  }

  Stream<List<FriendRequest>> watchIncoming(String meUid) {
    return _firestore
        .collection('users')
        .doc(meUid)
        .collection('friendRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FriendRequest.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<FriendRequest>> watchOutgoing(String meUid) {
    return _firestore
        .collectionGroup('friendRequests')
        .where('fromUserId', isEqualTo: meUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FriendRequest.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<int> watchPendingCount(String meUid) {
    final metaRef = _firestore
        .collection('users')
        .doc(meUid)
        .collection('friendMeta')
        .doc('meta');
    return metaRef.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) {
        return -1;
      }
      final val = data['pendingCountCache'] as int?;
      return val ?? -1;
    });
  }
}
