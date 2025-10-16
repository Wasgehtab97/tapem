import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/services/device_usage_summary_service.dart';

void main() {
  group('DeviceUsageSummaryService', () {
    test('returns cached summaries and aggregates recent dates', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('deviceUsageSummary')
          .doc('gym1')
          .collection('devices')
          .doc('d1')
          .set({
        'name': 'Device 1',
        'description': 'Test',
        'sessionCount': 12,
        'rollingSessions': {
          'last7Days': 2,
          'last30Days': 5,
          'last90Days': 8,
          'last365Days': 10,
          'all': 12,
        },
        'recentDates': [Timestamp.fromDate(DateTime(2024, 1, 10))],
      });

      var reads = 0;
      final service = DeviceUsageSummaryService(
        firestore: firestore,
        onRead: () => reads++,
      );

      final state = await service.loadSummaries('gym1');
      expect(state.entries, hasLength(1));
      final entry = state.entries.first;
      expect(entry.countForRangeKey('last30Days'), 5);
      expect(entry.totalSessions, 12);
      expect(reads, 1);

      // Subsequent loads should use the cache without additional reads.
      await service.loadSummaries('gym1');
      expect(reads, 1);

      final dates = await service.fetchRecentActivityDates('gym1');
      expect(dates, contains(DateTime(2024, 1, 10)));
    });
  });
}
