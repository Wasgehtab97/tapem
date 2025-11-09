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

    test('maps day summary documents with anonymized payload', () async {
      final feedRef = firestore
          .collection('gyms')
          .doc('gym1')
          .collection('feed_events')
          .doc('2024-11-01_user1');

      await feedRef.set({
        'type': 'day_summary',
        'createdAt': Timestamp.fromDate(DateTime.utc(2024, 11, 1, 12)),
        'dayKey': '2024-11-01',
      });

      final events = await source.streamFeed(gymId: 'gym1').first;
      expect(events, hasLength(1));
      final event = events.first;
      expect(event.type, FeedEventType.daySummary);
      expect(event.dayKey, '2024-11-01');
      expect(event.createdAt, DateTime.utc(2024, 11, 1, 12));
    });

    test('derives day key from document id when field missing', () async {
      final feedRef = firestore
          .collection('gyms')
          .doc('gym1')
          .collection('feed_events')
          .doc('2024-11-02_user1');

      await feedRef.set({
        'type': 'session_summary',
        'createdAt': Timestamp.fromDate(DateTime.utc(2024, 11, 2, 8)),
      });

      final events = await source.streamFeed(gymId: 'gym1').first;
      expect(events.first.type, FeedEventType.daySummary);
      expect(events.first.dayKey, '2024-11-02');
    });
  });
}
