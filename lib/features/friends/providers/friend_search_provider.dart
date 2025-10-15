import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/user_search_source.dart';
import '../domain/models/public_profile.dart';
import 'friends_provider.dart';

class FriendSearchProvider extends ChangeNotifier {
  FriendSearchProvider(this._source);

  final UserSearchSource _source;
  final Duration _cacheTtl = const Duration(minutes: 2);

  String query = '';
  List<PublicProfile> results = [];
  bool loading = false;
  String? error;

  Timer? _debounce;
  int _requestId = 0;
  final Map<String, _CachedSearchResult> _cache =
      <String, _CachedSearchResult>{};

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
    final cached = _cache[q];
    if (cached != null && _isFresh(cached.timestamp)) {
      results = cached.results;
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

  Future<void> _runSearch(String q, int requestId,
      {bool forceRefresh = false}) async {
    try {
      final res = await _source.searchByUsernamePrefix(
        q,
        forceRefresh: forceRefresh,
      );
      if (requestId != _requestId) return;
      results = res;
      _cache[q] = _CachedSearchResult(
        results: res,
        timestamp: DateTime.now(),
      );
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

  Future<void> refresh() async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) {
      return;
    }
    final currentRequest = ++_requestId;
    loading = true;
    notifyListeners();
    await _runSearch(q, currentRequest, forceRefresh: true);
  }

  void clearCache() {
    _cache.clear();
  }

  bool _isFresh(DateTime timestamp) {
    return DateTime.now().difference(timestamp) < _cacheTtl;
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

class _CachedSearchResult {
  _CachedSearchResult({required this.results, required this.timestamp});

  final List<PublicProfile> results;
  final DateTime timestamp;
}

enum FriendSearchCta {
  self,
  friend,
  incomingPending,
  outgoingPending,
  none,
}

