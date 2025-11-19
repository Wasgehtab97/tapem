import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/rest_stats/data/rest_stats_service.dart';
import 'package:tapem/features/rest_stats/domain/models/rest_stat_summary.dart';
import 'package:tapem/features/rest_stats/providers/rest_stats_provider.dart';

class _FakeRestStatsService extends RestStatsService {
  _FakeRestStatsService() : super(firestore: FakeFirebaseFirestore());

  List<RestStatSummary> result = const [];
  int fetchCount = 0;

  @override
  Future<List<RestStatSummary>> fetchStats({
    required String gymId,
    required String userId,
  }) async {
    fetchCount++;
    return result;
  }
}

AuthViewState _authState({String? gymId, String? userId}) {
  return AuthViewState(
    isLoading: false,
    isLoggedIn: gymId != null && userId != null,
    isAdmin: false,
    gymContextStatus:
        gymId != null ? GymContextStatus.ready : GymContextStatus.initial,
    gymCode: gymId,
    userId: userId,
    error: null,
  );
}

Future<void> _pumpEventQueue() async {
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('restStatsProvider reloads when auth context changes', () async {
    final fakeService = _FakeRestStatsService();
    fakeService.result = const [
      RestStatSummary(
        deviceId: 'd1',
        deviceName: 'Device 1',
        sampleCount: 1,
        sumActualRestMs: 1000,
        sumPlannedRestMs: 0,
        plannedSampleCount: 0,
      ),
    ];
    final authState = StateController(_authState(gymId: 'gymA', userId: 'user1'));
    final container = ProviderContainer(
      overrides: [
        restStatsServiceProvider.overrideWithValue(fakeService),
        authViewStateProvider.overrideWith((ref) => authState.state),
      ],
    );
    addTearDown(container.dispose);

    final provider = container.read(restStatsProvider);
    await provider.load(gymId: 'gymA', userId: 'user1');
    expect(fakeService.fetchCount, 1);
    expect(provider.stats, isNotEmpty);

    fakeService.result = const [
      RestStatSummary(
        deviceId: 'd2',
        deviceName: 'Device 2',
        sampleCount: 2,
        sumActualRestMs: 2000,
        sumPlannedRestMs: 0,
        plannedSampleCount: 0,
      ),
    ];

    authState.state = _authState(gymId: 'gymB', userId: 'user1');
    container.invalidate(authViewStateProvider);
    await _pumpEventQueue();
    await _pumpEventQueue();

    expect(fakeService.fetchCount, 2);
    expect(provider.stats.single.deviceId, 'd2');
  });
}
