import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_search_source.dart';
import '../domain/models/public_profile.dart';
import 'friends_data_providers.dart';
import 'friends_provider.dart';

class FriendSearchState {
  const FriendSearchState({
    this.query = '',
    this.results = const [],
    this.loading = false,
    this.error,
  });

  final String query;
  final List<PublicProfile> results;
  final bool loading;
  final String? error;

  FriendSearchState copyWith({
    String? query,
    List<PublicProfile>? results,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return FriendSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class FriendSearchNotifier extends Notifier<FriendSearchState> {
  Timer? _debounce;
  StreamSubscription<List<PublicProfile>>? _sub;
  late UserSearchSource _source;

  @override
  FriendSearchState build() {
    _source = ref.watch(userSearchSourceProvider);
    ref.onDispose(() {
      _debounce?.cancel();
      _sub?.cancel();
    });
    return const FriendSearchState();
  }

  void updateQuery(String value) {
    state = state.copyWith(query: value, clearError: true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _startSearch);
  }

  void _startSearch() {
    _sub?.cancel();
    final q = state.query.trim().toLowerCase();
    if (kDebugMode) {
      debugPrint('[FriendSearch] search start "$q"');
    }
    if (q.length < 2) {
      state = state.copyWith(
        results: const [],
        loading: false,
        clearError: true,
      );
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    _sub = _source.streamByUsernamePrefix(q).listen((res) {
      state = state.copyWith(results: res, loading: false);
    }, onError: (e) {
      state = state.copyWith(error: e.toString(), loading: false);
      if (kDebugMode) {
        debugPrint('[FriendSearch] error $e');
      }
    });
  }

  FriendSearchCta ctaFor(String uid, FriendsState friends) {
    if (friends.isSelf(uid)) return FriendSearchCta.self;
    if (friends.isFriend(uid)) return FriendSearchCta.friend;
    if (friends.hasIncomingPending(uid)) {
      return FriendSearchCta.incomingPending;
    }
    if (friends.hasOutgoingPending(uid)) {
      return FriendSearchCta.outgoingPending;
    }
    return FriendSearchCta.none;
  }
}

enum FriendSearchCta {
  self,
  friend,
  incomingPending,
  outgoingPending,
  none,
}

final friendSearchProvider =
    NotifierProvider<FriendSearchNotifier, FriendSearchState>(
  FriendSearchNotifier.new,
);
