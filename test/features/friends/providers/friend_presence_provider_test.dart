import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/friends/providers/friend_presence_provider.dart';
import 'package:tapem/features/friends/providers/friends_provider.dart';

class _FakeFriendPresenceStreamFactory implements FriendPresenceStreamFactory {
  final Map<String, StreamController<bool?>> statsControllers = {};
  final Map<String, StreamController<bool>> logControllers = {};
  final Map<String, int> statsCancelCounts = {};

  @override
  Stream<bool?> watchStats({required String uid, required String dayKey}) {
    final controller = StreamController<bool?>(
      onCancel: () {
        statsCancelCounts[uid] = (statsCancelCounts[uid] ?? 0) + 1;
      },
    );
    statsControllers[uid] = controller;
    return controller.stream;
  }

  @override
  Stream<bool> watchLogs({
    required String uid,
    required DateTime start,
    required DateTime end,
  }) {
    final controller = StreamController<bool>();
    logControllers[uid] = controller;
    return controller.stream;
  }
}

AuthViewState _authState(String gymId, String userId) {
  return AuthViewState(
    isLoading: false,
    isLoggedIn: true,
    isGuest: false,
    isAdmin: false,
    isCoach: false,
    gymContextStatus: GymContextStatus.ready,
    gymCode: gymId,
    userId: userId,
    error: null,
  );
}

final _testFriendIdsProvider = StateProvider<List<String>>((ref) => const []);

void main() {
  test('friendPresenceProvider unsubscribes on auth change', () async {
    final factory = _FakeFriendPresenceStreamFactory();
    final authState = StateController(_authState('gym1', 'user1'));
    final container = ProviderContainer(
      overrides: [
        friendPresenceStreamFactoryProvider.overrideWithValue(factory),
        friendIdsProvider.overrideWith((ref) => ref.watch(_testFriendIdsProvider)),
        authViewStateProvider.overrideWith((ref) => authState.state),
      ],
    );
    addTearDown(container.dispose);

    container.read(friendPresenceProvider);
    await Future<void>.delayed(Duration.zero);

    container.read(_testFriendIdsProvider.notifier).state = const ['friend1'];
    await Future<void>.delayed(Duration.zero);

    expect(factory.statsControllers.containsKey('friend1'), isTrue);

    authState.state = _authState('gym2', 'user2');
    container.invalidate(authViewStateProvider);
    await Future<void>.delayed(Duration.zero);

    expect(factory.statsCancelCounts['friend1'], 1);

    container.read(_testFriendIdsProvider.notifier).state = const ['friend1'];
    await Future<void>.delayed(Duration.zero);

    expect(factory.statsControllers.containsKey('friend1'), isTrue);
  });
}
