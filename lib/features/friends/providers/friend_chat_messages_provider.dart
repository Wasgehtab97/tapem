import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/friend_chat_source.dart';
import '../domain/models/friend_message.dart';

class FriendChatMessagesProvider extends ChangeNotifier {
  FriendChatMessagesProvider(this._source);

  final FriendChatSource _source;

  final Duration _cacheTtl = const Duration(minutes: 2);
  final Duration _pollInterval = const Duration(seconds: 30);

  List<FriendMessage> _messages = const <FriendMessage>[];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  String? _meUid;
  String? _friendUid;
  DateTime? _lastFetch;
  Timer? _pollTimer;

  List<FriendMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get hasMore => _hasMore;

  void listen({required String meUid, required String friendUid}) {
    if (meUid.isEmpty || friendUid.isEmpty) {
      detach();
      return;
    }
    final changed = _meUid != meUid || _friendUid != friendUid;
    _meUid = meUid;
    _friendUid = friendUid;
    if (changed) {
      final cached = _source.getCachedMessages(meUid, friendUid);
      if (cached.messages.isNotEmpty) {
        _messages = cached.messages;
        _hasMore = cached.hasMore;
        _cursor = cached.lastDocument;
        notifyListeners();
      } else {
        _messages = const <FriendMessage>[];
        _hasMore = true;
        _cursor = null;
        notifyListeners();
      }
      _lastFetch = null;
    }
    unawaited(_load(force: changed));
    _ensurePolling();
  }

  Future<void> refresh() async {
    await _load(force: true);
  }

  Future<void> loadMore() async {
    await _load(loadMore: true);
  }

  void detach() {
    _meUid = null;
    _friendUid = null;
    _messages = const <FriendMessage>[];
    _cursor = null;
    _hasMore = true;
    _lastFetch = null;
    _stopPolling();
    notifyListeners();
  }

  Future<void> _load({bool force = false, bool loadMore = false}) async {
    final uid = _meUid;
    final friend = _friendUid;
    if (uid == null || friend == null) {
      return;
    }

    if (loadMore) {
      if (_loadingMore || !_hasMore) {
        return;
      }
      if (_cursor == null && _messages.isNotEmpty) {
        // No cursor available yet; perform a fresh load to establish it.
        await _load(force: true);
        if (_cursor == null) {
          return;
        }
      }
    } else {
      if (_loading) {
        return;
      }
      if (!force && _lastFetch != null) {
        final delta = DateTime.now().difference(_lastFetch!);
        if (delta < _cacheTtl) {
          final cached = _source.getCachedMessages(uid, friend);
          if (cached.messages.isNotEmpty) {
            _messages = cached.messages;
            _hasMore = cached.hasMore;
            _cursor = cached.lastDocument;
            notifyListeners();
            return;
          }
        }
      }
    }

    if (loadMore) {
      _loadingMore = true;
    } else {
      _loading = true;
    }
    notifyListeners();
    try {
      final snapshot = await _source.fetchMessages(
        uid,
        friend,
        forceRefresh: force && !loadMore,
        startAfter: loadMore ? _cursor : null,
      );
      _messages = snapshot.messages;
      _hasMore = snapshot.hasMore;
      _cursor = snapshot.lastDocument;
      _lastFetch = DateTime.now();
      notifyListeners();
    } finally {
      if (loadMore) {
        _loadingMore = false;
      } else {
        _loading = false;
      }
    }
  }

  void _ensurePolling() {
    if (_meUid == null || _friendUid == null) {
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
