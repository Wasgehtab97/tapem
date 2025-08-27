import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/friends_source.dart';
import '../data/friends_api.dart';
import '../domain/models/friend.dart';
import '../domain/models/friend_request.dart';

class FriendsProvider extends ChangeNotifier {
  FriendsProvider(
    this._source,
    this._api,
  );

  final FriendsSource _source;
  final FriendsApi _api;

  List<Friend> friends = [];
  List<FriendRequest> incomingPending = [];
  List<FriendRequest> outgoingPending = [];
  int pendingCount = 0;
  bool isBusy = false;
  String? error;

  StreamSubscription? _friendsSub;
  StreamSubscription? _incomingSub;
  StreamSubscription? _outgoingSub;
  StreamSubscription? _countSub;

  void listen(String meUid) {
    _friendsSub?.cancel();
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _countSub?.cancel();

    selfUid = meUid;
    _friendsSub = _source.watchFriends(meUid).listen((f) {
      friends = f;
      friendsUids = f.map((e) => e.friendUid).toSet();
      notifyListeners();
    });
    _incomingSub = _source.watchIncoming(meUid).listen((r) {
      incomingPending = r;
      if (pendingCount < 0) {
        pendingCount = r.length;
      }
      notifyListeners();
    });
    _outgoingSub = _source.watchOutgoing(meUid).listen((r) {
      outgoingPending = r;
      outgoingUids = r.map((e) => e.toUserId).toSet();
      notifyListeners();
    });
    _countSub = _source.watchPendingCount(meUid).listen((c) {
      pendingCount = c < 0 ? incomingPending.length : c;
      notifyListeners();
    });
  }

  Future<void> sendRequest(String toUid, {String? message}) async {
    outgoingUids.add(toUid);
    notifyListeners();
    try {
      await _guard(() => _api.sendFriendRequest(toUid, message: message));
    } catch (_) {
      outgoingUids.remove(toUid);
      rethrow;
    }
  }

  Future<void> accept(String requestId, String toUid) async {
    await _guard(() => _api.accept(requestId, toUid));
  }

  Future<void> decline(String requestId, String toUid) async {
    await _guard(() => _api.decline(requestId, toUid));
  }

  Future<void> cancel(String requestId, String toUid) async {
    await _guard(() => _api.cancel(requestId, toUid));
  }

  Future<void> removeFriend(String otherUid) async {
    await _guard(() => _api.removeFriend(otherUid));
  }

  Future<void> markIncomingSeen() async {
    await _guard(() async {
      await _api.markIncomingSeen();
      pendingCount = 0;
    });
  }

  Set<String> friendsUids = {};
  Set<String> outgoingUids = {};
  String? selfUid;

  bool isSelf(String uid) => uid == selfUid;
  bool isFriend(String uid) => friendsUids.contains(uid);
  bool isOutgoing(String uid) => outgoingUids.contains(uid);

  Future<void> _guard(Future<void> Function() action) async {
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _friendsSub?.cancel();
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _countSub?.cancel();
    super.dispose();
  }
}
