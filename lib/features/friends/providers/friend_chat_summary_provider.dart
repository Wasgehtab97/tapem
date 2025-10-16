import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/friend_chat_api.dart';
import '../data/friend_chat_source.dart';
import '../domain/models/friend_chat_summary.dart';

class FriendChatSummaryProvider extends ChangeNotifier {
  FriendChatSummaryProvider(this._source, this._api);

  final FriendChatSource _source;
  final FriendChatApi _api;

  final Duration _cacheTtl = const Duration(minutes: 2);
  // Poll summaries only every four minutes to keep background traffic low.
  final Duration _pollInterval = const Duration(minutes: 4);

  Map<String, FriendChatSummary> _summaries = {};
  String? _selfUid;
  Timer? _pollTimer;
  DateTime? _lastFetch;
  bool _loading = false;
  final Set<Object> _visibleTokens = <Object>{};

  Map<String, FriendChatSummary> get summaries => Map.unmodifiable(_summaries);

  int get unreadCount =>
      _summaries.values.where((element) => element.hasUnread).length;

  void listen(String uid) {
    if (uid.isEmpty) {
      _selfUid = null;
      _summaries = {};
      _stopPolling();
      _visibleTokens.clear();
      notifyListeners();
      return;
    }
    final changed = _selfUid != uid;
    _selfUid = uid;
    final cached = _source.getCachedSummaries(uid);
    if (cached.isNotEmpty) {
      _summaries = {for (final s in cached) s.friendUid: s};
      notifyListeners();
    } else if (changed) {
      _summaries = {};
      notifyListeners();
    }
    if (_visibleTokens.isNotEmpty) {
      unawaited(_load(force: changed));
    }
    _ensurePolling();
  }

  Future<void> refresh() async {
    await _load(force: true);
  }

  void setVisibility(Object token, bool isVisible) {
    if (isVisible) {
      final added = _visibleTokens.add(token);
      if (added) {
        _ensurePolling();
        unawaited(_load(force: true));
      }
    } else {
      _visibleTokens.remove(token);
      if (_visibleTokens.isEmpty) {
        _stopPolling();
      }
    }
    _ensurePolling();
  }

  FriendChatSummary? summaryFor(String friendUid) => _summaries[friendUid];

  Future<void> markRead(String friendUid) async {
    final summary = _summaries[friendUid];
    if (summary != null && !summary.hasUnread) {
      return;
    }
    try {
      await _api.markConversationRead(friendUid);
      if (summary != null) {
        _summaries = {
          ..._summaries,
          friendUid: summary.copyWith(hasUnread: false),
        };
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FriendChat] markRead failed: $e');
      }
    }
  }

  Future<void> _load({bool force = false}) async {
    final uid = _selfUid;
    if (uid == null || uid.isEmpty) return;
    if (_loading) return;
    final hasVisibleListener = _visibleTokens.isNotEmpty;
    final hasUnread = unreadCount > 0;
    if (!force && !hasVisibleListener && !hasUnread) {
      return;
    }
    if (!force && _lastFetch != null) {
      final delta = DateTime.now().difference(_lastFetch!);
      if (delta < _cacheTtl) {
        final cached = _source.getCachedSummaries(uid);
        if (cached.isNotEmpty) {
          _summaries = {for (final s in cached) s.friendUid: s};
          notifyListeners();
          _ensurePolling();
        }
        return;
      }
    }
    _loading = true;
    try {
      final summaries = await _source.fetchSummaries(
        uid,
        forceRefresh: force,
      );
      _summaries = {for (final s in summaries) s.friendUid: s};
      _lastFetch = DateTime.now();
      notifyListeners();
      _ensurePolling();
    } finally {
      _loading = false;
    }
  }

  void _ensurePolling() {
    final shouldPoll =
        _selfUid != null && (_visibleTokens.isNotEmpty || unreadCount > 0);
    if (!shouldPoll) {
      _stopPolling();
      return;
    }
    _pollTimer ??= Timer.periodic(_pollInterval, (_) {
      unawaited(_load());
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
