import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:tapem/features/community/domain/models/community_stats.dart';
import 'package:tapem/features/community/domain/models/feed_event.dart';
import 'package:tapem/features/community/presentation/providers/community_providers.dart';
import 'package:tapem/features/community/presentation/screens/community_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';

Future<void> _pumpCommunityScreen(
  WidgetTester tester, {
  required Stream<CommunityStats> statsStream,
  required Stream<List<FeedEvent>> feedStream,
}) async {
  await tester.pumpWidget(
    riverpod.ProviderScope(
      overrides: [
        currentGymIdProvider.overrideWithValue('gym1'),
        communityStatsProvider.overrideWithProvider(
          (period) => riverpod.StreamProvider.autoDispose(
            (ref) => statsStream,
          ),
        ),
        communityFeedProvider.overrideWithProvider(
          riverpod.StreamProvider.autoDispose(
            (ref) => feedStream,
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CommunityScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CommunityScreen', () {
    setUp(() {
      Intl.defaultLocale = 'en';
    });

    testWidgets('shows loading indicator while stats stream is pending', (tester) async {
      final statsController = StreamController<CommunityStats>.broadcast();
      final feedController = StreamController<List<FeedEvent>>.broadcast();

      addTearDown(() async {
        await statsController.close();
        await feedController.close();
      });

      await _pumpCommunityScreen(
        tester,
        statsStream: statsController.stream,
        feedStream: feedController.stream,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders empty placeholder when stats have no data', (tester) async {
      final statsController = StreamController<CommunityStats>.broadcast();
      final feedController = StreamController<List<FeedEvent>>.broadcast();

      addTearDown(() async {
        await statsController.close();
        await feedController.close();
      });

      await _pumpCommunityScreen(
        tester,
        statsStream: statsController.stream,
        feedStream: feedController.stream,
      );

      statsController.add(CommunityStats.zero);
      feedController.add(const <FeedEvent>[]);

      await tester.pump();

      final context = tester.element(find.byType(CommunityScreen));
      final loc = AppLocalizations.of(context)!;

      expect(find.text(loc.communityEmptyState), findsOneWidget);
    });

    testWidgets('renders error screen with retry button when stats stream fails', (tester) async {
      final statsController = StreamController<CommunityStats>.broadcast();
      final feedController = StreamController<List<FeedEvent>>.broadcast();

      addTearDown(() async {
        await statsController.close();
        await feedController.close();
      });

      await _pumpCommunityScreen(
        tester,
        statsStream: statsController.stream,
        feedStream: feedController.stream,
      );

      statsController.addError(Exception('boom'));
      feedController.add(const <FeedEvent>[]);

      await tester.pump();

      final context = tester.element(find.byType(CommunityScreen));
      final loc = AppLocalizations.of(context)!;

      expect(find.text(loc.communityErrorState), findsOneWidget);
      expect(find.text(loc.communityRetryButton), findsWidgets);
    });

    testWidgets('renders KPIs and feed entries when data is available', (tester) async {
      final statsController = StreamController<CommunityStats>.broadcast();
      final feedController = StreamController<List<FeedEvent>>.broadcast();

      addTearDown(() async {
        await statsController.close();
        await feedController.close();
      });

      await _pumpCommunityScreen(
        tester,
        statsStream: statsController.stream,
        feedStream: feedController.stream,
      );

      statsController.add(
        const CommunityStats(
          totalSessions: 4,
          totalExercises: 6,
          totalSets: 18,
          totalReps: 120,
          totalVolumeKg: 1850,
        ),
      );
      feedController.add([
        FeedEvent(
          type: FeedEventType.daySummary,
          createdAt: DateTime.utc(2024, 11, 1, 8, 30),
          dayKey: '2024-11-01',
        ),
      ]);

      await tester.pump();

      final context = tester.element(find.byType(CommunityScreen));
      final loc = AppLocalizations.of(context)!;
      expect(find.text(loc.communityKpiHeadline), findsOneWidget);
      expect(find.text(loc.communityKpiSessions), findsOneWidget);
      expect(find.text(loc.communityKpiExercises), findsOneWidget);
      expect(find.text(loc.communityKpiSets), findsOneWidget);
      expect(find.text(loc.communityKpiReps), findsOneWidget);
      expect(find.text(loc.communityKpiVolume), findsOneWidget);
      expect(find.text(loc.communityFeedTrainingDayHeadline), findsOneWidget);
      expect(find.textContaining('Nov'), findsWidgets);

      await tester.tap(find.text('Week'));
      await tester.pump();

      expect(find.textContaining('1,850'), findsWidgets);
    });

    testWidgets('does not overflow when constrained and showing errors', (tester) async {
      final statsController = StreamController<CommunityStats>.broadcast();
      final feedController = StreamController<List<FeedEvent>>.broadcast();

      addTearDown(() async {
        await statsController.close();
        await feedController.close();
      });

      final binding = tester.binding.window;
      final previousSize = binding.physicalSize;
      final previousRatio = binding.devicePixelRatio;
      binding.physicalSizeTestValue = const Size(400, 400);
      binding.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        binding.physicalSizeTestValue = previousSize;
        binding.devicePixelRatioTestValue = previousRatio;
      });

      await _pumpCommunityScreen(
        tester,
        statsStream: statsController.stream,
        feedStream: feedController.stream,
      );

      statsController.addError(Exception('boom'));
      feedController.addError(Exception('feed boom'));

      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
