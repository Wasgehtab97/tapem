import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/user_search_source.dart';
import '../domain/models/public_profile.dart';
import 'friends_provider.dart';

class FriendSearchProvider extends ChangeNotifier {
  FriendSearchProvider(this._source);

  final UserSearchSource _source;

  String query = '';
  List<PublicProfile> results = [];
  bool loading = false;
  String? error;

  Timer? _debounce;
  int _requestId = 0;

  void updateQuery(String value) {
    query = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _startSearch);
  }

  void _startSearch() {
    final q = query.trim().toLowerCase();
    if (kDebugMode) {
      debugPrint('[FriendSearch] search start "$q"');
    }
    if (q.length < 2) {
      results = [];
      loading = false;
      error = null;
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();

    final currentRequest = ++_requestId;
    unawaited(_runSearch(q, currentRequest));
  }

  Future<void> _runSearch(String q, int requestId) async {
    try {
      final res = await _source.searchByUsernamePrefix(q);
      if (requestId != _requestId) return;
      results = res;
      loading = false;
      notifyListeners();
    } catch (e) {
      if (requestId != _requestId) return;
      error = e.toString();
      if (kDebugMode) {
        debugPrint('[FriendSearch] error $e');
      }
      loading = false;
      notifyListeners();
    }
  }

  FriendSearchCta ctaFor(String uid, FriendsProvider friends) {
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

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

enum FriendSearchCta {
  self,
  friend,
  incomingPending,
  outgoingPending,
  none,
}

