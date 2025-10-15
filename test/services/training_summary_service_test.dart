import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/services/training_summary_service.dart';

void main() {
  group('TrainingSummaryService.fetchGroupUsageCounts', () {
    test('aggregates device counts per muscle group and caches results', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('trainingSummary')
          .doc('user1')
          .collection('aggregate')
          .doc('overview')
          .set({
        'deviceCounts': {
          'deviceA': {'count': 3},
          'deviceB': {'count': 2},
        },
      });

      await firestore
          .collection('gyms')
          .doc('gym1')
          .collection('muscleGroups')
          .doc('groupA')
          .set({
        'primaryDeviceIds': ['deviceA'],
        'secondaryDeviceIds': <String>[],
      });

      await firestore
          .collection('gyms')
          .doc('gym1')
          .collection('muscleGroups')
          .doc('groupB')
          .set({
        'primaryDeviceIds': ['deviceB'],
      });

      var readCount = 0;
      final service = TrainingSummaryService(
        firestore: firestore,
        onRead: () => readCount++,
      );

      final counts = await service.fetchGroupUsageCounts(
        gymId: 'gym1',
        userId: 'user1',
      );

      expect(counts['groupA'], 3);
      expect(counts['groupB'], 2);
      expect(readCount, 2); // aggregate + muscle groups

      // Second call should hit the cache and avoid additional reads.
      final cached = await service.fetchGroupUsageCounts(
        gymId: 'gym1',
        userId: 'user1',
      );
      expect(cached['groupA'], 3);
      expect(readCount, 2);
    });
  });
}
