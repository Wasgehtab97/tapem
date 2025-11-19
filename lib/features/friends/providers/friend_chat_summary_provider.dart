import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';
import '../data/friend_chat_api.dart';
import '../data/friend_chat_source.dart';
import '../domain/models/friend_chat_summary.dart';
import 'friends_data_providers.dart';

class FriendChatSummaryState {
  const FriendChatSummaryState({
    this.selfUid,
    this.summaries = const <String, FriendChatSummary>{},
  });

  final String? selfUid;
  final Map<String, FriendChatSummary> summaries;

  int get unreadCount =>
      summaries.values.where((element) => element.hasUnread).length;

  FriendChatSummary? summaryFor(String friendUid) => summaries[friendUid];

  FriendChatSummaryState copyWith({
    String? selfUid,
    Map<String, FriendChatSummary>? summaries,
  }) {
    return FriendChatSummaryState(
      selfUid: selfUid ?? this.selfUid,
      summaries: summaries ?? this.summaries,
    );
  }
}

class FriendChatSummaryNotifier extends Notifier<FriendChatSummaryState> {
  StreamSubscription<List<FriendChatSummary>>? _sub;
  late FriendChatSource _source;
  late FriendChatApi _api;

  @override
  FriendChatSummaryState build() {
    _source = ref.watch(friendChatSourceProvider);
    _api = ref.watch(friendChatApiProvider);

    ref.onDispose(() => _sub?.cancel());

    ref.listen<AuthViewState>(
      authViewStateProvider,
      (previous, next) {
        final userChanged = previous?.userId != next.userId;
        final gymChanged = previous?.gymCode != next.gymCode;
        final uid = next.userId;
        if (!next.isLoggedIn || uid == null || uid.isEmpty) {
          _sub?.cancel();
          _sub = null;
          state = const FriendChatSummaryState();
          return;
        }
        if (userChanged || gymChanged || state.selfUid != uid) {
          _listen(uid);
        }
      },
      fireImmediately: true,
    );

    return const FriendChatSummaryState();
  }

  Future<void> markRead(String friendUid) async {
    final summary = state.summaries[friendUid];
    if (summary != null && !summary.hasUnread) {
      return;
    }
    await _api.markConversationRead(friendUid);
    if (summary != null) {
      final nextSummaries = Map<String, FriendChatSummary>.from(state.summaries);
      nextSummaries[friendUid] = summary.copyWith(hasUnread: false);
      state = state.copyWith(summaries: nextSummaries);
    }
  }

  void _listen(String uid) {
    _sub?.cancel();
    state = FriendChatSummaryState(selfUid: uid);
    _sub = _source.watchSummaries(uid).listen((event) {
      final next = {
        for (final summary in event) summary.friendUid: summary,
      };
      state = state.copyWith(summaries: next);
    });
  }
}

final friendChatSummaryProvider =
    NotifierProvider<FriendChatSummaryNotifier, FriendChatSummaryState>(
  FriendChatSummaryNotifier.new,
);
