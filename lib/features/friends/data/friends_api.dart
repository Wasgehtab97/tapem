import 'package:cloud_functions/cloud_functions.dart';

class FriendsApi {
  FriendsApi({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<SendResult> sendFriendRequest(String toUid, {String? message}) async {
    try {
      final callable = _functions.httpsCallable('sendFriendRequest');
      final res = await callable.call({
        'toUserId': toUid,
        if (message != null) 'message': message,
      });
      return SendResult.fromMap(Map<String, dynamic>.from(res.data));
    } on FirebaseFunctionsException catch (e) {
      throw FriendsApiException.fromCode(e.code, e.message);
    }
  }

  Future<void> accept(String requestId, String toUid) =>
      _updateStatus(requestId, toUid, 'accept');

  Future<void> decline(String requestId, String toUid) =>
      _updateStatus(requestId, toUid, 'decline');

  Future<void> cancel(String requestId, String toUid) =>
      _updateStatus(requestId, toUid, 'cancel');

  Future<void> removeFriend(String otherUid) async {
    try {
      final callable = _functions.httpsCallable('removeFriend');
      await callable.call({'otherUserId': otherUid});
    } on FirebaseFunctionsException catch (e) {
      throw FriendsApiException.fromCode(e.code, e.message);
    }
  }

  Future<void> markIncomingSeen() async {
    try {
      final callable = _functions.httpsCallable('setFriendRequestsSeen');
      await callable.call();
    } on FirebaseFunctionsException catch (e) {
      throw FriendsApiException.fromCode(e.code, e.message);
    }
  }

  Future<void> _updateStatus(
    String requestId,
    String toUid,
    String action,
  ) async {
    try {
      final callable = _functions.httpsCallable('updateFriendRequestStatus');
      await callable.call({
        'requestId': requestId,
        'toUserId': toUid,
        'action': action,
      });
    } on FirebaseFunctionsException catch (e) {
      throw FriendsApiException.fromCode(e.code, e.message);
    }
  }
}

class SendResult {
  SendResult({required this.requestId});
  final String requestId;
  factory SendResult.fromMap(Map<String, dynamic> data) =>
      SendResult(requestId: data['requestId'] as String);
}

enum FriendsApiError {
  unauthenticated,
  invalidArgument,
  permissionDenied,
  alreadyExists,
  notFound,
  resourceExhausted,
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
      case 'resource-exhausted':
        return FriendsApiException(FriendsApiError.resourceExhausted, message);
      default:
        return FriendsApiException(FriendsApiError.unknown, message);
    }
  }
}
