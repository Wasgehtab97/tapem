import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FriendsApi {
  FriendsApi({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> sendRequest(String toUserId, {String? message}) async {
    final me = _auth.currentUser?.uid;
    if (me == null) {
      throw FriendsApiException(FriendsApiError.unauthenticated);
    }
    if (me == toUserId) {
      throw FriendsApiException(
          FriendsApiError.invalidArgument, 'Cannot send to self');
    }
    final docId = '${me}_$toUserId';
    final now = FieldValue.serverTimestamp();
    final ref = _firestore.collection('friendRequests').doc(docId);
    try {
      await ref.set({
        'fromUserId': me,
        'toUserId': toUserId,
        'status': 'pending',
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));
      if (kDebugMode) {
        debugPrint('[Friends] send to=$toUserId ok');
      }
    } on FirebaseException catch (e) {
      throw FriendsApiException.fromCode(e.code, e.message);
    }
  }

  Future<void> cancelRequest(String toUserId) async {
    final me = _auth.currentUser?.uid;
    if (me == null) {
      throw FriendsApiException(FriendsApiError.unauthenticated);
    }
    final docId = '${me}_$toUserId';
    final ref = _firestore.collection('friendRequests').doc(docId);
    final now = FieldValue.serverTimestamp();
    try {
      final snap = await ref.get();
      final data = snap.data();
      if (data == null || data['fromUserId'] != me || data['status'] != 'pending') {
        throw FriendsApiException(FriendsApiError.failedPrecondition);
      }
      await ref.set({'status': 'canceled', 'updatedAt': now}, SetOptions(merge: true));
      if (kDebugMode) {
        debugPrint('[Friends] cancel to=$toUserId ok');
      }
    } on FirebaseException catch (e) {
      throw FriendsApiException.fromCode(e.code, e.message);
    }
  }

  Future<void> acceptRequest(String fromUserId) async {
    final me = _auth.currentUser?.uid;
    if (me == null) {
      throw FriendsApiException(FriendsApiError.unauthenticated);
    }
    final docId = '${fromUserId}_$me';
    final ref = _firestore.collection('friendRequests').doc(docId);
    final now = FieldValue.serverTimestamp();
    try {
      final snap = await ref.get();
      final data = snap.data();
      if (data == null || data['toUserId'] != me || data['status'] != 'pending') {
        throw FriendsApiException(FriendsApiError.failedPrecondition);
      }
      await ref.set({'status': 'accepted', 'updatedAt': now}, SetOptions(merge: true));
      final edge = _firestore
          .collection('users')
          .doc(me)
          .collection('friends')
          .doc(fromUserId);
      await edge.set({'createdAt': now}, SetOptions(merge: true));
      if (kDebugMode) {
        debugPrint('[Friends] accept from=$fromUserId ok');
      }
    } on FirebaseException catch (e) {
      throw FriendsApiException.fromCode(e.code, e.message);
    }
  }

  Future<void> declineRequest(String fromUserId) async {
    final me = _auth.currentUser?.uid;
    if (me == null) {
      throw FriendsApiException(FriendsApiError.unauthenticated);
    }
    final docId = '${fromUserId}_$me';
    final ref = _firestore.collection('friendRequests').doc(docId);
    final now = FieldValue.serverTimestamp();
    try {
      final snap = await ref.get();
      final data = snap.data();
      if (data == null || data['toUserId'] != me || data['status'] != 'pending') {
        throw FriendsApiException(FriendsApiError.failedPrecondition);
      }
      await ref.set({'status': 'declined', 'updatedAt': now}, SetOptions(merge: true));
      if (kDebugMode) {
        debugPrint('[Friends] decline from=$fromUserId ok');
      }
    } on FirebaseException catch (e) {
      throw FriendsApiException.fromCode(e.code, e.message);
    }
  }

  /// Removes the friendship to [otherUserId] and cleans up related data.
  ///
  /// Deletes friend edges and optional `friendMeta` documents for both users
  /// and hard-deletes any non-accepted friend requests between them. The
  /// operation is executed as a [WriteBatch] and is idempotent.
  Future<void> removeFriend(String otherUserId) async {
    final me = _auth.currentUser?.uid;
    if (me == null) {
      throw FriendsApiException(FriendsApiError.unauthenticated);
    }

    final batch = _firestore.batch();
    final meFriend = _firestore
        .collection('users')
        .doc(me)
        .collection('friends')
        .doc(otherUserId);
    final otherFriend = _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('friends')
        .doc(me);
    final meMeta = _firestore
        .collection('users')
        .doc(me)
        .collection('friendMeta')
        .doc(otherUserId);
    final otherMeta = _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('friendMeta')
        .doc(me);

    if (kDebugMode) {
      debugPrint('[Friends] remove begin me=$me other=$otherUserId');
      debugPrint('[Friends] delete ${meFriend.path}');
      debugPrint('[Friends] delete ${otherFriend.path}');
      debugPrint('[Friends] delete ${meMeta.path}');
      debugPrint('[Friends] delete ${otherMeta.path}');
    }

    batch.delete(meFriend);
    batch.delete(otherFriend);
    batch.delete(meMeta);
    batch.delete(otherMeta);

    final req1 =
        _firestore.collection('friendRequests').doc('${me}_$otherUserId');
    final req2 =
        _firestore.collection('friendRequests').doc('${otherUserId}_$me');
    for (final doc in [req1, req2]) {
      final snap = await doc.get();
      final data = snap.data();
      if (data != null && data['status'] != 'accepted') {
        if (kDebugMode) {
          debugPrint('[Friends] delete ${doc.path}');
        }
        batch.delete(doc);
      }
    }

    try {
      await batch.commit();
      if (kDebugMode) {
        debugPrint('[Friends] remove complete me=$me other=$otherUserId');
      }
    } on FirebaseException catch (e) {
      throw FriendsApiException.fromCode(e.code, e.message);
    }
  }

  Future<void> ensureFriendEdge(String otherUserId) async {
    final me = _auth.currentUser?.uid;
    if (me == null) {
      throw FriendsApiException(FriendsApiError.unauthenticated);
    }
    final now = FieldValue.serverTimestamp();
    final ref = _firestore
        .collection('users')
        .doc(me)
        .collection('friends')
        .doc(otherUserId);
    try {
      await ref.set({'createdAt': now}, SetOptions(merge: true));
      if (kDebugMode) {
        debugPrint('[Friends] ensure edge to=$otherUserId ok');
      }
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
