import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/features/story_card/data/story_analytics_service.dart';
import 'package:tapem/features/story_card/data/story_timeline_repository.dart';
import 'package:tapem/features/story_card/domain/story_timeline_filter.dart';
import 'package:tapem/features/story_card/presentation/controllers/story_timeline_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StoryTimelineController', () {
    late FakeFirebaseFirestore firestore;
    late StoryTimelineRepository repository;
    late StoryAnalyticsService analytics;
    late StoryTimelineController controller;
    late DateTime now;
    late DateTime withinTenDays;
    late DateTime withinTwentyDays;
    late DateTime withinFortyFiveDays;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      repository = StoryTimelineRepository(firestore: firestore);
      analytics = StoryAnalyticsService(firestore: firestore);

      now = DateTime.now();
      withinTenDays = now.subtract(const Duration(days: 10));
      withinTwentyDays = now.subtract(const Duration(days: 20));
      withinFortyFiveDays = now.subtract(const Duration(days: 45));

      await firestore
          .collection('users')
          .doc('user')
          .collection('stories')
          .doc('a')
          .set({
        'sessionId': 'a',
        'createdAt': Timestamp.fromDate(withinTenDays),
        'prTypes': ['e1rm'],
        'prCount': 1,
        'xpTotal': 120,
        'xpBase': 100,
        'xpBonus': 20,
        'previewColors': ['#111111', '#222222'],
        'gymId': 'gym-a',
      });

      await firestore
          .collection('users')
          .doc('user')
          .collection('stories')
          .doc('b')
          .set({
        'sessionId': 'b',
        'createdAt': Timestamp.fromDate(withinTwentyDays),
        'prTypes': ['volume'],
        'prCount': 1,
        'xpTotal': 90,
        'previewColors': ['#333333', '#444444'],
        'gymId': 'gym-b',
      });

      await firestore
          .collection('users')
          .doc('user')
          .collection('stories')
          .doc('c')
          .set({
        'sessionId': 'c',
        'createdAt': Timestamp.fromDate(withinFortyFiveDays),
        'prTypes': [],
        'prCount': 0,
        'xpTotal': 60,
        'previewColors': ['#555555', '#666666'],
        'gymId': 'gym-b',
      });

      await firestore
          .collection('users')
          .doc('user')
          .collection('storyMetrics')
          .doc('summary')
          .set({
        'sessionCount': 3,
        'prSessionCount': 2,
        'prEventCount': 2,
        'shareCount': 1,
        'storyShownCount': 2,
        'timelineOpenCount': 1,
        'totalXp': 270,
        'updatedAt': Timestamp.fromDate(now),
      });

      controller = StoryTimelineController(
        userId: 'user',
        repository: repository,
        analytics: analytics,
      );
    });

    test('refresh loads stories ordered by createdAt descending', () async {
      await controller.refresh(preferCache: false);
      expect(controller.entries.length, 2);
      expect(controller.entries.first.sessionId, 'a');
      expect(controller.entries[1].sessionId, 'b');
    });

    test('applyFilter reduces entries to PR type', () async {
      await controller.refresh(preferCache: false);
      await controller.applyFilter(
        const StoryTimelineFilter(prFilter: StoryTimelinePrFilter.strength),
      );
      expect(controller.entries.length, 1);
      expect(controller.entries.first.sessionId, 'a');
    });

    test('applyFilter with allTime range includes older stories', () async {
      await controller.refresh(preferCache: false);
      await controller.applyFilter(
        controller.filter.copyWith(range: StoryTimelineRange.allTime),
      );
      expect(controller.entries.length, 3);
      expect(controller.entries.last.sessionId, 'c');
    });

    test('applyFilter with gymId filters to selected gym', () async {
      await controller.refresh(preferCache: false);
      await controller.applyFilter(
        controller.filter.copyWith(gymId: 'gym-b'),
      );
      expect(controller.entries.length, 1);
      expect(controller.entries.first.sessionId, 'b');
    });

    test('metrics stream is consumed on init', () async {
      await controller.init();
      await Future.delayed(const Duration(milliseconds: 10));
      final metrics = controller.metrics;
      expect(metrics, isNotNull);
      expect(metrics!.sessionCount, 3);
      expect(metrics.averageXpPerSession, closeTo(90, 0.01));
    });

    test('loadMore appends additional stories', () async {
      for (int i = 0; i < 25; i++) {
        await firestore
            .collection('users')
            .doc('user')
            .collection('stories')
            .doc('extra-$i')
            .set({
          'sessionId': 'extra-$i',
          'createdAt': Timestamp.fromDate(now.subtract(Duration(days: i))),
          'prTypes': [],
          'prCount': 0,
          'xpTotal': 10 + i,
          'previewColors': ['#777777', '#888888'],
        });
      }

      await controller.refresh(preferCache: false);
      final initialLength = controller.entries.length;
      expect(initialLength, 20);
      await controller.loadMore();
      expect(controller.entries.length, greaterThan(initialLength));
    });
  });
}
