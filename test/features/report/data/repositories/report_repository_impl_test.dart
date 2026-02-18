import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/observability/owner_query_budget_service.dart';
import 'package:tapem/features/report/data/repositories/report_repository_impl.dart';
import 'package:tapem/features/report/data/sources/firestore_report_source.dart';

void main() {
  group('ReportRepositoryImpl', () {
    late FakeFirebaseFirestore firestore;
    late OwnerQueryBudgetService queryBudgetService;
    late ReportRepositoryImpl repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      queryBudgetService = OwnerQueryBudgetService();
      queryBudgetService.resetForTests();
      repository = ReportRepositoryImpl(
        FirestoreReportSource(firestore),
        queryBudgetService,
      );
    });

    test(
      'uses daily aggregates when available for usage stats and heatmap',
      () async {
        await firestore.doc('gyms/g1/devices/d1').set({
          'name': 'Rower',
          'description': 'Cardio machine',
        });
        await firestore.doc('gyms/g1/devices/d2').set({
          'description': 'Strength machine',
        });

        await firestore.doc('gyms/g1/reportDaily/20260215').set({
          'dayKey': '20260215',
          'totalLogs': 5,
          'totalSessions': 4,
          'deviceSessionCounts': {'d1': 3, 'd2': 1},
          'hourBuckets': {'9': 2, '10': 1},
        });
        await firestore.doc('gyms/g1/reportDaily/20260216').set({
          'dayKey': '20260216',
          'totalLogs': 2,
          'totalSessions': 2,
          'deviceSessionCounts': {'d1': 2},
          'hourBuckets': {'8': 1},
        });

        final stats = await repository.fetchDeviceUsageStats('g1');
        final statsById = {for (final stat in stats) stat.id: stat};

        expect(statsById['d1']?.sessions, 5);
        expect(statsById['d2']?.sessions, 1);
        expect(statsById['d1']?.name, 'Rower');
        expect(statsById['d2']?.name, 'd2');

        final timestamps = await repository.fetchAllLogTimestamps('g1');
        expect(timestamps.length, 4);
        expect(
          timestamps.where((t) => t == DateTime.utc(2026, 2, 15, 9)).length,
          2,
        );
        expect(
          timestamps.where((t) => t == DateTime.utc(2026, 2, 15, 10)).length,
          1,
        );
        expect(
          timestamps.where((t) => t == DateTime.utc(2026, 2, 16, 8)).length,
          1,
        );
      },
    );

    test('applies since filter on daily aggregate path', () async {
      await firestore.doc('gyms/g1/devices/d1').set({'name': 'Rower'});
      await firestore.doc('gyms/g1/devices/d2').set({'name': 'Bike'});

      await firestore.doc('gyms/g1/reportDaily/20260215').set({
        'dayKey': '20260215',
        'deviceSessionCounts': {'d1': 3, 'd2': 1},
        'hourBuckets': {'9': 2},
      });
      await firestore.doc('gyms/g1/reportDaily/20260216').set({
        'dayKey': '20260216',
        'deviceSessionCounts': {'d1': 2},
        'hourBuckets': {'8': 1},
      });

      final stats = await repository.fetchDeviceUsageStats(
        'g1',
        since: DateTime.utc(2026, 2, 16),
      );
      final statsById = {for (final stat in stats) stat.id: stat};

      expect(statsById['d1']?.sessions, 2);
      expect(statsById['d2']?.sessions, 0);

      final timestamps = await repository.fetchAllLogTimestamps(
        'g1',
        since: DateTime.utc(2026, 2, 16),
      );
      expect(timestamps, [DateTime.utc(2026, 2, 16, 8)]);
    });

    test('falls back to legacy logs when no daily aggregates exist', () async {
      final base = DateTime.utc(2026, 2, 16, 12);
      await firestore.doc('gyms/g1/devices/d1').set({'name': 'Rower'});
      await firestore.doc('gyms/g1/devices/d2').set({'name': 'Bike'});

      await firestore.doc('gyms/g1/devices/d1/logs/l1').set({
        'sessionId': 's1',
        'timestamp': Timestamp.fromDate(base),
      });
      await firestore.doc('gyms/g1/devices/d1/logs/l2').set({
        'sessionId': 's1',
        'timestamp': Timestamp.fromDate(base.add(const Duration(minutes: 5))),
      });
      await firestore.doc('gyms/g1/devices/d1/logs/l3').set({
        'sessionId': 's2',
        'timestamp': Timestamp.fromDate(base.add(const Duration(minutes: 10))),
      });
      await firestore.doc('gyms/g1/devices/d1/logs/l4').set({
        'timestamp': Timestamp.fromDate(base.add(const Duration(minutes: 15))),
      });
      await firestore.doc('gyms/g1/devices/d2/logs/l5').set({
        'sessionId': '',
        'timestamp': Timestamp.fromDate(base.add(const Duration(minutes: 20))),
      });
      await firestore.doc('gyms/g1/devices/d2/logs/l6').set({
        'sessionId': 's9',
        'timestamp': Timestamp.fromDate(base.add(const Duration(minutes: 25))),
      });

      final stats = await repository.fetchDeviceUsageStats('g1');
      final statsById = {for (final stat in stats) stat.id: stat};

      expect(statsById['d1']?.sessions, 2);
      expect(statsById['d2']?.sessions, 1);

      final timestamps = await repository.fetchAllLogTimestamps('g1');
      expect(timestamps.length, 6);

      final usageMetric = queryBudgetService.metrics.metricFor(
        'owner.report.usage_stats',
      );
      expect(usageMetric.runs, 1);
      expect(usageMetric.lastQueries, 4);

      final heatmapMetric = queryBudgetService.metrics.metricFor(
        'owner.report.heatmap_timestamps',
      );
      expect(heatmapMetric.runs, 1);
      expect(heatmapMetric.lastQueries, 4);
    });
  });
}
