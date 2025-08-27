import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/friends_source.dart';
import '../data/friends_api.dart';
import '../data/public_profile_source.dart';
import '../domain/models/friend.dart';
import '../domain/models/friend_request.dart';
import '../domain/models/public_profile.dart';

class FriendsProvider extends ChangeNotifier {
  FriendsProvider(
    this._source,
    this._api,
    this._profileSource,
  );

  final FriendsSource _source;
  final FriendsApi _api;
  final PublicProfileSource _profileSource;

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

    _friendsSub = _source.watchFriends(meUid).listen((f) {
      friends = f;
      notifyListeners();
    });
    _incomingSub = _source.watchIncoming(meUid).listen((r) {
      incomingPending = r;
      notifyListeners();
    });
    _outgoingSub = _source.watchOutgoing(meUid).listen((r) {
      outgoingPending = r;
      notifyListeners();
    });
    _countSub = _source.watchPendingCount(meUid).listen((c) {
      pendingCount = c;
      notifyListeners();
    });
  }

  Future<void> sendRequest(String toUid, {String? message}) async {
    await _guard(() => _api.sendFriendRequest(toUid, message: message));
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
    await _guard(() => _api.markIncomingSeen());
  }

  Future<List<PublicProfile>> search(String prefix) {
    return _profileSource
        .searchByUsernamePrefix(prefix)
        .firstWhere((_) => true);
  }

  Future<void> _guard(Future<void> Function() action) async {
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = e.toString();
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
