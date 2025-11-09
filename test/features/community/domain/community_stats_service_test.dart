import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/core/time/time_windows.dart';
import 'package:tapem/features/community/data/firestore_community_stats_source.dart';
import 'package:tapem/features/community/domain/services/community_stats_service.dart';

void main() {
  group('CommunityStatsService', () {
    late FakeFirebaseFirestore firestore;
    late CommunityStatsService service;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      final source = FirestoreCommunityStatsSource(firestore: firestore);
      service = CommunityStatsService(
        source,
        clock: () => DateTime(2024, 11, 1, 9, 30),
      );
    });

    test('streamToday emits zero stats when doc missing', () async {
      final stream = service.streamToday('gym1');
      final stats = await stream.first;
      expect(stats.totalReps, 0);
      expect(stats.totalVolumeKg, 0);
      expect(stats.totalSessions, 0);
      expect(stats.totalExercises, 0);
      expect(stats.totalSets, 0);
    });

    test('streamToday emits live updates', () async {
      final statsRef = firestore
          .collection('gyms')
          .doc('gym1')
          .collection('stats_daily')
          .doc('2024-11-01');

      await statsRef.set({
        'date': DateTime.utc(2024, 11, 1),
        'repsTotal': 10,
        'volumeTotal': 120.0,
        'trainingSessions': 1,
        'exerciseTotal': 4,
        'setTotal': 12,
      });

      final stream = service.streamToday('gym1');
      final stats = await stream.firstWhere((value) => value.totalReps == 10);
      expect(stats.totalVolumeKg, 120);
      expect(stats.totalSessions, 1);
      expect(stats.totalExercises, 4);
      expect(stats.totalSets, 12);
    });

    test('loadPeriod aggregates stats within window', () async {
      final collection = firestore
          .collection('gyms')
          .doc('gym1')
          .collection('stats_daily');

      await collection.doc('2024-10-30').set({
        'date': DateTime.utc(2024, 10, 30),
        'repsTotal': 40,
        'volumeTotal': 500,
        'trainingSessions': 2,
        'exerciseTotal': 5,
        'setTotal': 18,
      });
      await collection.doc('2024-10-31').set({
        'date': DateTime.utc(2024, 10, 31),
        'repsTotal': 60,
        'volumeTotal': 800,
        'trainingSessions': 3,
        'exerciseTotal': 8,
        'setTotal': 22,
      });
      await collection.doc('2024-11-01').set({
        'date': DateTime.utc(2024, 11, 1),
        'repsTotal': 30,
        'volumeTotal': 350,
        'trainingSessions': 1,
        'exerciseTotal': 3,
        'setTotal': 10,
      });

      final window = weekUtcRange(DateTime(2024, 11, 1));
      final stats = await service.loadPeriod('gym1', window);
      expect(stats.totalReps, 130);
      expect(stats.totalVolumeKg, 1650);
      expect(stats.totalSessions, 6);
      expect(stats.totalExercises, 16);
      expect(stats.totalSets, 50);
    });
  });
}
