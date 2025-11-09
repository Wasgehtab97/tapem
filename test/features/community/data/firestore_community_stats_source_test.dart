import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/features/community/data/firestore_community_stats_source.dart';
import 'package:tapem/features/community/domain/models/feed_event.dart';

void main() {
  group('FirestoreCommunityStatsSource feed mapping', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreCommunityStatsSource source;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      source = FirestoreCommunityStatsSource(firestore: firestore);
    });

    test('maps day summary documents with aggregation fields', () async {
      final feedRef = firestore
          .collection('gyms')
          .doc('gym1')
          .collection('feed_events')
          .doc('2024-11-01_user1');

      await feedRef.set({
        'type': 'day_summary',
        'createdAt': Timestamp.fromDate(DateTime.utc(2024, 11, 1, 12)),
        'userId': 'user1',
        'username': 'Alice',
        'dayKey': '2024-11-01',
        'reps': 44,
        'volume': 1420.456,
        'sessionCount': 2,
        'exerciseCount': 2,
        'setCount': 4,
      });

      final events = await source.streamFeed(gymId: 'gym1').first;
      expect(events, hasLength(1));
      final event = events.first;
      expect(event.type, FeedEventType.daySummary);
      expect(event.reps, 44);
      expect(event.volumeKg, 1420.46);
      expect(event.sessionCount, 2);
      expect(event.exerciseCount, 2);
      expect(event.setCount, 4);
      expect(event.dayKey, '2024-11-01');
    });

    test('maps legacy session_summary as day summary with zeroed aggregates',
        () async {
      final feedRef = firestore
          .collection('gyms')
          .doc('gym1')
          .collection('feed_events')
          .doc('legacy');

      await feedRef.set({
        'type': 'session_summary',
        'createdAt': Timestamp.fromDate(DateTime.utc(2024, 11, 2, 8)),
        'reps': 12,
        'volume': 120,
      });

      final events = await source.streamFeed(gymId: 'gym1').first;
      expect(events.first.type, FeedEventType.daySummary);
      expect(events.first.sessionCount, 0);
      expect(events.first.exerciseCount, 0);
      expect(events.first.setCount, 0);
    });
  });
}
