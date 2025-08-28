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
  StreamSubscription? _sub;

  void updateQuery(String value) {
    query = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _startSearch);
  }

  void _startSearch() {
    _sub?.cancel();
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
    _sub = _source.streamByUsernamePrefix(q).listen((res) {
      results = res;
      loading = false;
      notifyListeners();
    }, onError: (e) {
      error = e.toString();
      if (kDebugMode) {
        debugPrint('[FriendSearch] error $e');
      }
      loading = false;
      notifyListeners();
    });
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
    _sub?.cancel();
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

