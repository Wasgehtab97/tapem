import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/friend_chat_api.dart';
import '../data/friend_chat_source.dart';
import '../domain/models/friend_chat_summary.dart';

class FriendChatSummaryProvider extends ChangeNotifier {
  FriendChatSummaryProvider(this._source, this._api);

  final FriendChatSource _source;
  final FriendChatApi _api;

  StreamSubscription<List<FriendChatSummary>>? _sub;
  Map<String, FriendChatSummary> _summaries = {};
  String? _selfUid;

  Map<String, FriendChatSummary> get summaries => Map.unmodifiable(_summaries);

  int get unreadCount =>
      _summaries.values.where((element) => element.hasUnread).length;

  void listen(String uid) {
    if (_selfUid == uid && _sub != null) {
      return;
    }
    _sub?.cancel();
    _selfUid = uid;
    _sub = _source.watchSummaries(uid).listen((event) {
      _summaries = {for (final s in event) s.friendUid: s};
      notifyListeners();
    });
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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
