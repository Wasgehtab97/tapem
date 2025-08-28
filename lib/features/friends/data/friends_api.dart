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

  Future<void> removeFriend(String otherUserId) async {
    final me = _auth.currentUser?.uid;
    if (me == null) {
      throw FriendsApiException(FriendsApiError.unauthenticated);
    }
    try {
      await _firestore
          .collection('users')
          .doc(me)
          .collection('friends')
          .doc(otherUserId)
          .delete();
      if (kDebugMode) {
        debugPrint('[Friends] remove friend=$otherUserId ok');
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
