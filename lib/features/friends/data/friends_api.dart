import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsApi {
  FriendsApi({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> sendFriendRequest(String toUid, {String? message}) async {
    final me = _auth.currentUser?.uid;
    if (me == null) {
      throw FriendsApiException(FriendsApiError.unauthenticated);
    }
    if (me == toUid) {
      throw FriendsApiException(
          FriendsApiError.invalidArgument, 'Cannot send to self');
    }
    final docId = '${me}_$toUid';
    final now = FieldValue.serverTimestamp();
    final doc = _firestore
        .collection('users')
        .doc(toUid)
        .collection('friendRequests')
        .doc(docId);
    try {
      await doc.set({
        'fromUserId': me,
        'toUserId': toUid,
        'status': 'pending',
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw FriendsApiException.fromCode(e.code, e.message);
    }
  }

  Future<void> acceptRequest({required String fromUid}) async {
    final me = _auth.currentUser?.uid;
    if (me == null) {
      throw FriendsApiException(FriendsApiError.unauthenticated);
    }
    final now = FieldValue.serverTimestamp();
    final reqId = '${fromUid}_$me';
    final reqRef = _firestore
        .collection('users')
        .doc(me)
        .collection('friendRequests')
        .doc(reqId);
    final myFriendRef =
        _firestore.collection('users').doc(me).collection('friends').doc(fromUid);
    try {
      await reqRef.set({'status': 'accepted', 'updatedAt': now},
          SetOptions(merge: true));
      await myFriendRef.set({
        'friendUid': fromUid,
        'since': now,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw FriendsApiException.fromCode(e.code, e.message);
    }
  }

  Future<void> declineRequest({required String fromUid}) async {
    final me = _auth.currentUser?.uid;
    if (me == null) {
      throw FriendsApiException(FriendsApiError.unauthenticated);
    }
    final now = FieldValue.serverTimestamp();
    final reqId = '${fromUid}_$me';
    try {
      await _firestore
          .collection('users')
          .doc(me)
          .collection('friendRequests')
          .doc(reqId)
          .set({'status': 'declined', 'updatedAt': now}, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw FriendsApiException.fromCode(e.code, e.message);
    }
  }

  Future<void> cancelRequest({required String toUid}) async {
    final me = _auth.currentUser?.uid;
    if (me == null) {
      throw FriendsApiException(FriendsApiError.unauthenticated);
    }
    final now = FieldValue.serverTimestamp();
    final reqId = '${me}_$toUid';
    try {
      await _firestore
          .collection('users')
          .doc(toUid)
          .collection('friendRequests')
          .doc(reqId)
          .set({'status': 'canceled', 'updatedAt': now}, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw FriendsApiException.fromCode(e.code, e.message);
    }
  }

  Future<void> removeFriend(String otherUid) async {
    final me = _auth.currentUser?.uid;
    if (me == null) {
      throw FriendsApiException(FriendsApiError.unauthenticated);
    }
    try {
      await _firestore
          .collection('users')
          .doc(me)
          .collection('friends')
          .doc(otherUid)
          .delete();
    } on FirebaseException catch (e) {
      throw FriendsApiException.fromCode(e.code, e.message);
    }
  }

  Future<void> ensureFriendEdge(String otherUid) async {
    final me = _auth.currentUser?.uid;
    if (me == null) {
      throw FriendsApiException(FriendsApiError.unauthenticated);
    }
    final now = FieldValue.serverTimestamp();
    final ref = _firestore
        .collection('users')
        .doc(me)
        .collection('friends')
        .doc(otherUid);
    try {
      await ref.set({
        'friendUid': otherUid,
        'since': now,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw FriendsApiException.fromCode(e.code, e.message);
    }
  }
}

enum FriendsApiError {
  unauthenticated,
  invalidArgument,
  permissionDenied,
  alreadyExists,
  notFound,
  failedPrecondition,
  unknown,
}

class FriendsApiException implements Exception {
  FriendsApiException(this.code, [this.message]);
  final FriendsApiError code;
  final String? message;

  factory FriendsApiException.fromCode(String code, String? message) {
    switch (code) {
      case 'unauthenticated':
        return FriendsApiException(FriendsApiError.unauthenticated, message);
      case 'invalid-argument':
        return FriendsApiException(FriendsApiError.invalidArgument, message);
      case 'permission-denied':
        return FriendsApiException(FriendsApiError.permissionDenied, message);
      case 'already-exists':
        return FriendsApiException(FriendsApiError.alreadyExists, message);
      case 'not-found':
        return FriendsApiException(FriendsApiError.notFound, message);
      case 'failed-precondition':
        return FriendsApiException(
            FriendsApiError.failedPrecondition, message);
      default:
        return FriendsApiException(FriendsApiError.unknown, message);
    }
  }
}
