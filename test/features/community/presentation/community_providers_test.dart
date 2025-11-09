import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/community/data/firestore_community_stats_source.dart';
import 'package:tapem/features/community/domain/models/community_stats.dart';
import 'package:tapem/features/community/domain/services/community_stats_service.dart';
import 'package:tapem/features/community/presentation/providers/community_providers.dart';

class _SpyCommunityStatsService extends CommunityStatsService {
  _SpyCommunityStatsService()
      : super(FirestoreCommunityStatsSource(firestore: FakeFirebaseFirestore()));

  int todayCalls = 0;
  int rangeCalls = 0;

  final _todayController = StreamController<CommunityStats>.broadcast();
  final _rangeController = StreamController<CommunityStats>.broadcast();

  @override
  Stream<CommunityStats> streamToday(String gymId) {
    todayCalls++;
    return _todayController.stream;
  }

  @override
  Stream<CommunityStats> streamRange({
    required String gymId,
    required DateTime startUtc,
    required DateTime endUtc,
  }) {
    rangeCalls++;
    return _rangeController.stream;
  }

  void emitToday(CommunityStats stats) {
    _todayController.add(stats);
  }

  void emitRange(CommunityStats stats) {
    _rangeController.add(stats);
  }

  void dispose() {
    _todayController.close();
    _rangeController.close();
  }
}

void main() {
  group('communityStatsProvider', () {
    late _SpyCommunityStatsService service;
    late ProviderContainer container;

    setUp(() {
      service = _SpyCommunityStatsService();
      container = ProviderContainer(
        overrides: [
          currentGymIdProvider.overrideWithValue('gym-1'),
          communityStatsServiceProvider.overrideWithValue(service),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      service.dispose();
    });

    test('uses streamToday for the today period', () async {
      final future = container
          .read(communityStatsProvider(CommunityPeriod.today).future);

      service.emitToday(
        const CommunityStats(
          totalSessions: 2,
          totalExercises: 5,
          totalSets: 9,
          totalReps: 7,
          totalVolumeKg: 15,
        ),
      );

      final stats = await future;

      expect(stats.totalReps, 7);
      expect(service.todayCalls, 1);
      expect(service.rangeCalls, 0);
    });

    test('uses streamRange for non-today periods', () async {
      final future = container
          .read(communityStatsProvider(CommunityPeriod.week).future);

      service.emitRange(
        const CommunityStats(
          totalSessions: 1,
          totalExercises: 2,
          totalSets: 4,
          totalReps: 3,
          totalVolumeKg: 8,
        ),
      );

      final stats = await future;

      expect(stats.totalReps, 3);
      expect(service.rangeCalls, 1);
      expect(service.todayCalls, 0);
    });
  });
}
