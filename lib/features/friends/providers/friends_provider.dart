import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';
import '../data/friends_api.dart';
import '../data/friends_source.dart';
import '../domain/models/friend.dart';
import '../domain/models/friend_request.dart';
import 'friends_data_providers.dart';

class FriendsState {
  const FriendsState({
    this.friends = const [],
    this.incomingPending = const [],
    this.outgoingPending = const [],
    this.pendingCount = 0,
    this.isBusy = false,
    this.error,
    this.friendsUids = const <String>{},
    this.outgoingPendingUids = const <String>{},
    this.incomingPendingUids = const <String>{},
    this.selfUid,
  });

  final List<Friend> friends;
  final List<FriendRequest> incomingPending;
  final List<FriendRequest> outgoingPending;
  final int pendingCount;
  final bool isBusy;
  final String? error;
  final Set<String> friendsUids;
  final Set<String> outgoingPendingUids;
  final Set<String> incomingPendingUids;
  final String? selfUid;

  FriendsState copyWith({
    List<Friend>? friends,
    List<FriendRequest>? incomingPending,
    List<FriendRequest>? outgoingPending,
    int? pendingCount,
    bool? isBusy,
    String? error,
    bool clearError = false,
    Set<String>? friendsUids,
    Set<String>? outgoingPendingUids,
    Set<String>? incomingPendingUids,
    String? selfUid,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      incomingPending: incomingPending ?? this.incomingPending,
      outgoingPending: outgoingPending ?? this.outgoingPending,
      pendingCount: pendingCount ?? this.pendingCount,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : error ?? this.error,
      friendsUids: friendsUids ?? this.friendsUids,
      outgoingPendingUids: outgoingPendingUids ?? this.outgoingPendingUids,
      incomingPendingUids: incomingPendingUids ?? this.incomingPendingUids,
      selfUid: selfUid ?? this.selfUid,
    );
  }

  bool isSelf(String uid) => uid == selfUid;
  bool isFriend(String uid) => friendsUids.contains(uid);
  bool hasOutgoingPending(String uid) => outgoingPendingUids.contains(uid);
  bool hasIncomingPending(String uid) => incomingPendingUids.contains(uid);
}

class FriendsNotifier extends Notifier<FriendsState> {
  StreamSubscription<List<Friend>>? _friendsSub;
  StreamSubscription<List<FriendRequest>>? _incomingSub;
  StreamSubscription<List<FriendRequest>>? _outgoingSub;
  StreamSubscription<List<FriendRequest>>? _outgoingAcceptedSub;
  late FriendsApi _api;

  @override
  FriendsState build() {
    final source = ref.watch(friendsSourceProvider);
    _api = ref.watch(friendsApiProvider);

    ref.onDispose(_cancelSubscriptions);

    ref.listen<AuthViewState>(
      authViewStateProvider,
      (previous, next) {
        final userChanged = previous?.userId != next.userId;
        final gymChanged = previous?.gymCode != next.gymCode;
        final userId = next.userId;
        if (!next.isLoggedIn || userId == null || userId.isEmpty) {
          _cancelSubscriptions();
          state = const FriendsState();
          return;
        }
        if (userChanged || gymChanged || state.selfUid != userId) {
          _startListening(source, userId);
        }
      },
      fireImmediately: true,
    );

    return const FriendsState();
  }

  void markIncomingSeen() {
    if (state.pendingCount == 0) {
      return;
    }
    state = state.copyWith(pendingCount: 0);
  }

  Future<void> sendRequest(String toUid, {String? message}) async {
    final pending = {...state.outgoingPendingUids, toUid};
    state = state.copyWith(outgoingPendingUids: pending);
    try {
      await _guard(() => _api.sendRequest(toUid, message: message));
    } catch (_) {
      final next = {...state.outgoingPendingUids}..remove(toUid);
      state = state.copyWith(outgoingPendingUids: next);
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
      final friends = state.friends.where((f) => f.friendUid != otherUid).toList();
      final incoming =
          state.incomingPending.where((r) => r.fromUserId != otherUid).toList();
      final outgoing =
          state.outgoingPending.where((r) => r.toUserId != otherUid).toList();
      final friendsUids = {...state.friendsUids}..remove(otherUid);
      final incomingUids = {...state.incomingPendingUids}..remove(otherUid);
      final outgoingUids = {...state.outgoingPendingUids}..remove(otherUid);
      state = state.copyWith(
        friends: friends,
        incomingPending: incoming,
        outgoingPending: outgoing,
        pendingCount: incoming.length,
        friendsUids: friendsUids,
        incomingPendingUids: incomingUids,
        outgoingPendingUids: outgoingUids,
      );
    });
  }

  @Deprecated('Use remove')
  Future<void> removeFriend(String otherUid) => remove(otherUid);

  Future<void> _guard(Future<void> Function() action) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await action();
    } catch (e) {
      final message =
          e is FriendsApiException ? e.message ?? e.code.toString() : e.toString();
      state = state.copyWith(error: message);
      rethrow;
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  void _startListening(FriendsSource source, String uid) {
    _cancelSubscriptions();
    state = FriendsState(selfUid: uid);
    _friendsSub = source.watchFriends(uid).listen((friends) {
      state = state.copyWith(
        friends: friends,
        friendsUids: friends.map((f) => f.friendUid).toSet(),
      );
    });
    _incomingSub = source.watchIncoming(uid).listen((requests) {
      state = state.copyWith(
        incomingPending: requests,
        incomingPendingUids: requests.map((r) => r.fromUserId).toSet(),
        pendingCount: requests.length,
      );
    });
    _outgoingSub = source.watchOutgoing(uid).listen((requests) {
      state = state.copyWith(
        outgoingPending: requests,
        outgoingPendingUids: requests.map((r) => r.toUserId).toSet(),
      );
    });
    _outgoingAcceptedSub = source.watchOutgoingAccepted(uid).listen(
      (requests) async {
        for (final req in requests) {
          if (!state.friendsUids.contains(req.toUserId)) {
            try {
              await _api.ensureFriendEdge(req.toUserId);
            } catch (_) {
              // Ignore errors; sync will retry on next event.
            }
          }
        }
      },
    );
  }

  void _cancelSubscriptions() {
    _friendsSub?.cancel();
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _outgoingAcceptedSub?.cancel();
    _friendsSub = null;
    _incomingSub = null;
    _outgoingSub = null;
    _outgoingAcceptedSub = null;
  }
}

final friendsProvider = NotifierProvider<FriendsNotifier, FriendsState>(
  FriendsNotifier.new,
);

final friendIdsProvider = Provider<List<String>>((ref) {
  final friendsState = ref.watch(friendsProvider);
  return List.unmodifiable(friendsState.friends.map((f) => f.friendUid));
});
