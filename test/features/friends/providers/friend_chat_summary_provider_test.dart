import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/friends/data/friend_chat_api.dart';
import 'package:tapem/features/friends/data/friend_chat_source.dart';
import 'package:tapem/features/friends/domain/models/friend_chat_summary.dart';
import 'package:tapem/features/friends/domain/models/friend_message.dart';
import 'package:tapem/features/friends/providers/friend_chat_summary_provider.dart';
import 'package:tapem/features/friends/providers/friends_data_providers.dart';

class _FakeFriendChatSource implements FriendChatSource {
  final Map<String, StreamController<List<FriendChatSummary>>> controllers = {};
  final Map<String, int> cancelCounts = {};

  @override
  Stream<List<FriendChatSummary>> watchSummaries(String meUid) {
    final controller = StreamController<List<FriendChatSummary>>(
      onCancel: () {
        cancelCounts[meUid] = (cancelCounts[meUid] ?? 0) + 1;
      },
    );
    controllers[meUid] = controller;
    return controller.stream;
  }

  @override
  Stream<List<FriendMessage>> watchMessages(String meUid, String friendUid,
      {int limit = 200}) {
    return const Stream.empty();
  }
}

class _FakeFriendChatApi implements FriendChatApi {
  @override
  Future<void> markConversationRead(String friendUid) async {}

  @override
  Future<void> sendMessage(String friendUid, String text) async {}
}

AuthViewState _authState(String gymId, String userId) {
  return AuthViewState(
    isLoading: false,
    isLoggedIn: true,
    isAdmin: false,
    gymContextStatus: GymContextStatus.ready,
    gymCode: gymId,
    userId: userId,
    error: null,
  );
}

void main() {
  test('friendChatSummaryProvider re-subscribes when auth user changes', () async {
    final chatSource = _FakeFriendChatSource();
    final authState = StateController(_authState('gym1', 'user1'));
    final container = ProviderContainer(
      overrides: [
        friendChatSourceProvider.overrideWithValue(chatSource),
        friendChatApiProvider.overrideWithValue(_FakeFriendChatApi()),
        authViewStateProvider.overrideWith((ref) => authState.state),
      ],
    );
    addTearDown(container.dispose);

    container.read(friendChatSummaryProvider);
    await Future<void>.delayed(Duration.zero);

    expect(chatSource.controllers.containsKey('user1'), isTrue);

    authState.state = _authState('gym2', 'user2');
    container.invalidate(authViewStateProvider);
    await Future<void>.delayed(Duration.zero);

    expect(chatSource.cancelCounts['user1'], 1);
    expect(chatSource.controllers.containsKey('user2'), isTrue);
  });
}
