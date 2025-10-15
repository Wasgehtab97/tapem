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

  final Duration _cacheTtl = const Duration(minutes: 5);
  final Duration _pollInterval = const Duration(minutes: 5);

  List<Friend> friends = [];
  List<FriendRequest> incomingPending = [];
  List<FriendRequest> outgoingPending = [];
  int pendingCount = 0;
  bool isBusy = false;
  String? error;

  DateTime? _lastFriendsFetch;
  DateTime? _lastIncomingFetch;
  DateTime? _lastOutgoingFetch;
  DateTime? _lastOutgoingAcceptedFetch;
  final Set<String> _processedAcceptedRequestIds = <String>{};

  Timer? _pollTimer;
  bool _loading = false;

  void listen(String meUid) {
    if (meUid.isEmpty) {
      _stopPolling();
      selfUid = null;
      _resetState();
      return;
    }

    final uidChanged = selfUid != meUid;
    selfUid = meUid;
    if (uidChanged) {
      _stopPolling();
      friends = [];
      incomingPending = [];
      outgoingPending = [];
      friendsUids.clear();
      incomingPendingUids.clear();
      outgoingPendingUids.clear();
      pendingCount = 0;
      _lastFriendsFetch = null;
      _lastIncomingFetch = null;
      _lastOutgoingFetch = null;
      _lastOutgoingAcceptedFetch = null;
      _processedAcceptedRequestIds.clear();
      notifyListeners();
    }

    unawaited(_loadAll(forceRefresh: uidChanged));
    _ensurePolling();
  }

  Future<void> sendRequest(String toUid, {String? message}) async {
    outgoingPendingUids.add(toUid);
    notifyListeners();
    try {
      await _guard(() => _api.sendRequest(toUid, message: message));
    } catch (_) {
      outgoingPendingUids.remove(toUid);
      rethrow;
    }
  }

  Future<void> accept(String fromUid) async {
    await _guard(() => _api.acceptRequest(fromUid));
  }

  Future<void> decline(String fromUid) async {
    await _guard(() => _api.declineRequest(fromUid));
  }

  Future<void> cancel(String toUid) async {
    await _guard(() => _api.cancelRequest(toUid));
  }

  Future<void> remove(String otherUid) async {
    await _guard(() async {
      await _api.removeFriend(otherUid);
      friends.removeWhere((f) => f.friendUid == otherUid);
      friendsUids.remove(otherUid);
      incomingPending.removeWhere((r) => r.fromUserId == otherUid);
      outgoingPending.removeWhere((r) => r.toUserId == otherUid);
      incomingPendingUids.remove(otherUid);
      outgoingPendingUids.remove(otherUid);
      pendingCount = incomingPending.length;
      notifyListeners();
    });
  }

  @Deprecated('Use remove')
  Future<void> removeFriend(String otherUid) => remove(otherUid);

  void markIncomingSeen() {
    pendingCount = 0;
    notifyListeners();
  }

  Set<String> friendsUids = {};
  Set<String> outgoingPendingUids = {};
  Set<String> incomingPendingUids = {};
  String? selfUid;

  bool isSelf(String uid) => uid == selfUid;
  bool isFriend(String uid) => friendsUids.contains(uid);
  bool hasOutgoingPending(String uid) => outgoingPendingUids.contains(uid);
  bool hasIncomingPending(String uid) => incomingPendingUids.contains(uid);

  bool _isFresh(DateTime? timestamp) {
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheTtl;
  }

  Future<void> _loadAll({bool forceRefresh = false}) async {
    if (_loading) return;
    final uid = selfUid;
    if (uid == null || uid.isEmpty) return;

    _loading = true;
    var shouldNotify = false;
    try {
      if (forceRefresh || !_isFresh(_lastFriendsFetch)) {
        final data = await _source.fetchFriends(uid);
        friends = data;
        friendsUids = data.map((e) => e.friendUid).toSet();
        _lastFriendsFetch = DateTime.now();
        shouldNotify = true;
      }

      if (forceRefresh || !_isFresh(_lastIncomingFetch)) {
        final data = await _source.fetchIncomingPending(uid);
        incomingPending = data;
        incomingPendingUids = data.map((e) => e.fromUserId).toSet();
        pendingCount = data.length;
        _lastIncomingFetch = DateTime.now();
        shouldNotify = true;
      }

      if (forceRefresh || !_isFresh(_lastOutgoingFetch)) {
        final data = await _source.fetchOutgoingPending(uid);
        outgoingPending = data;
        outgoingPendingUids = data.map((e) => e.toUserId).toSet();
        _lastOutgoingFetch = DateTime.now();
        shouldNotify = true;
      }

      if (forceRefresh || !_isFresh(_lastOutgoingAcceptedFetch)) {
        final accepted = await _source.fetchOutgoingAccepted(uid);
        _lastOutgoingAcceptedFetch = DateTime.now();
        for (final req in accepted) {
          if (_processedAcceptedRequestIds.contains(req.requestId)) {
            continue;
          }
          if (friendsUids.contains(req.toUserId)) {
            _processedAcceptedRequestIds.add(req.requestId);
            continue;
          }
          try {
            await _api.ensureFriendEdge(req.toUserId);
            _processedAcceptedRequestIds.add(req.requestId);
          } catch (_) {
            // ignore errors; sync will retry on next poll
          }
        }
      }
    } finally {
      _loading = false;
      if (shouldNotify) notifyListeners();
    }
  }

  void refresh() {
    unawaited(_loadAll(forceRefresh: true));
  }

  void _ensurePolling() {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_loadAll());
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _resetState() {
    friends = [];
    incomingPending = [];
    outgoingPending = [];
    friendsUids.clear();
    incomingPendingUids.clear();
    outgoingPendingUids.clear();
    pendingCount = 0;
    _lastFriendsFetch = null;
    _lastIncomingFetch = null;
    _lastOutgoingFetch = null;
    _lastOutgoingAcceptedFetch = null;
    _processedAcceptedRequestIds.clear();
    notifyListeners();
  }

  Future<void> _guard(Future<void> Function() action) async {
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      if (e is FriendsApiException) {
        error = e.message ?? e.code.toString();
      } else {
        error = e.toString();
      }
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
