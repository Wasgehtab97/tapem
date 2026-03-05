import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/story_session/domain/models/story_achievement.dart';
import 'package:tapem/features/story_session/domain/models/story_challenge_highlight.dart';
import 'package:tapem/features/story_session/domain/models/story_daily_xp.dart';
import 'package:tapem/features/story_session/domain/models/story_session_summary.dart';
import 'package:tapem/features/story_session/presentation/widgets/story_session_dialog.dart';
import 'package:tapem/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('StorySessionDialog surfaces capped penalties with net XP', (
    tester,
  ) async {
    const dailyXp = StoryDailyXp(
      xp: 85,
      rulesetId: 'xp_ruleset_v2',
      rulesetVersion: 1,
      components: [
        StoryXpComponent(
          code: 'base_daily',
          amount: 60,
          metadata: {'trainingDayIndex': 2},
        ),
        StoryXpComponent(code: 'comeback_bonus', amount: 25),
      ],
      penalties: [
        StoryXpPenalty(
          id: 'penalty-streak-break',
          type: 'streakBreakPenalty',
          delta: -30,
          day: '2024-02-20',
          metadata: {'gapIndex': 1, 'idleDays': 49, 'streakBeforeBreak': 1},
        ),
        StoryXpPenalty(
          id: 'penalty-week-1',
          type: 'missedWeekPenalty',
          delta: 0,
          day: '2024-02-13',
          metadata: {'gapIndex': 1, 'idleDays': 49, 'missedWeekNumber': 1},
        ),
      ],
    );

    final summary = StorySessionSummary(
      gymId: 'g1',
      userId: 'u1',
      dayKey: '2024-02-20',
      totalXp: 85,
      generatedAt: DateTime.utc(2024, 2, 21),
      achievements: const [],
      stats: const StorySessionStats(
        exerciseCount: 4,
        setCount: 12,
        durationMs: 3720000,
      ),
      dailyXp: dailyXp,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: StorySessionDialog(summary: summary)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('+85 XP'), findsOneWidget);
    expect(find.text('-30 XP'), findsOneWidget);
    expect(find.text('01:02'), findsOneWidget);
    expect(find.text('Streak break penalty'), findsNothing);
    expect(find.text('Missed week penalty'), findsNothing);
    expect(find.text('Ruleset: xp_ruleset_v2 v1'), findsNothing);

    await tester.tap(find.text('Penalties'));
    await tester.pumpAndSettle();

    expect(find.text('Penalty details'), findsOneWidget);
    expect(find.text('-30 XP'), findsWidgets);
    expect(find.text('0 XP'), findsOneWidget);
    expect(find.text('Streak break penalty'), findsOneWidget);
    expect(find.text('Missed week penalty'), findsOneWidget);
    expect(find.text('Ruleset: xp_ruleset_v2 v1'), findsOneWidget);
  });

  testWidgets('StorySessionDialog shows active challenge progress section', (
    tester,
  ) async {
    final summary = StorySessionSummary(
      gymId: 'g1',
      userId: 'u1',
      dayKey: '2026-02-15',
      totalXp: 70,
      generatedAt: DateTime.utc(2026, 2, 15, 20, 0),
      achievements: const [],
      challengeHighlights: [
        StoryChallengeHighlight(
          challengeId: 'c1',
          title: '16x in 4 Wochen',
          description: 'Bleib konstant dran',
          goalType: 'workout_days',
          progress: 6,
          target: 16,
          xpReward: 500,
          durationWeeks: 4,
          start: DateTime.utc(2026, 2, 1),
          end: DateTime.utc(2026, 2, 28),
        ),
      ],
      stats: const StorySessionStats(
        exerciseCount: 3,
        setCount: 10,
        durationMs: 48 * 60 * 1000,
      ),
      dailyXp: const StoryDailyXp(
        xp: 70,
        components: [StoryXpComponent(code: 'base_daily', amount: 70)],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: StorySessionDialog(summary: summary)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Challenges'), findsOneWidget);
    expect(find.text('16x in 4 Wochen'), findsOneWidget);
    expect(find.text('Goal: 16 workouts in 4 calendar weeks'), findsOneWidget);
    expect(find.text('Progress: 6/16'), findsOneWidget);
    expect(find.text('+500 XP'), findsOneWidget);
    expect(find.text('Bleib konstant dran'), findsNothing);
    expect(find.text('+1'), findsNothing);
  });

  testWidgets(
    'StorySessionDialog uses horizontal swipe for multiple challenges',
    (tester) async {
      final summary = StorySessionSummary(
        gymId: 'g1',
        userId: 'u1',
        dayKey: '2026-02-20',
        totalXp: 90,
        generatedAt: DateTime.utc(2026, 2, 20, 21, 0),
        achievements: const [],
        challengeHighlights: [
          StoryChallengeHighlight(
            challengeId: 'c1',
            title: '16x in 4 Weeks',
            description: 'Go all in',
            goalType: 'workout_days',
            progress: 15,
            target: 16,
            xpReward: 500,
            durationWeeks: 4,
            start: DateTime.utc(2026, 2, 1),
            end: DateTime.utc(2026, 2, 28),
          ),
          StoryChallengeHighlight(
            challengeId: 'c2',
            title: 'Unstoppable (4x)',
            description: 'Second challenge',
            goalType: 'workout_days',
            progress: 1,
            target: 4,
            xpReward: 90,
            durationWeeks: 1,
            start: DateTime.utc(2026, 2, 17),
            end: DateTime.utc(2026, 2, 22),
          ),
        ],
        stats: const StorySessionStats(
          exerciseCount: 4,
          setCount: 12,
          durationMs: 52 * 60 * 1000,
        ),
        dailyXp: const StoryDailyXp(
          xp: 90,
          components: [StoryXpComponent(code: 'base_daily', amount: 90)],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: StorySessionDialog(summary: summary)),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('challenge-highlights-horizontal-list')),
        findsOneWidget,
      );
      expect(find.text('16x in 4 Weeks'), findsOneWidget);
      expect(find.text('Unstoppable (4x)'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
    },
  );

  testWidgets('StorySessionDialog avoids bottom overflow on compact screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final summary = StorySessionSummary(
      gymId: 'g1',
      userId: 'u1',
      dayKey: '2026-02-14',
      totalXp: 50,
      generatedAt: DateTime.utc(2026, 2, 14, 20, 0),
      achievements: const [
        StoryAchievement(
          type: StoryAchievementType.newDevice,
          deviceName: 'Kniebeuge',
        ),
        StoryAchievement(
          type: StoryAchievementType.newDevice,
          deviceName: 'Bankdruecken',
        ),
        StoryAchievement(
          type: StoryAchievementType.newDevice,
          deviceName: 'Chest Fly',
        ),
      ],
      stats: const StorySessionStats(
        exerciseCount: 3,
        setCount: 8,
        durationMs: 42 * 1000,
      ),
      dailyXp: const StoryDailyXp(
        xp: 50,
        components: [StoryXpComponent(code: 'base_daily', amount: 50)],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: StorySessionDialog(summary: summary)),
      ),
    );
    await tester.pumpAndSettle();

    final verticalLists = find.byWidgetPredicate((widget) {
      return widget is ListView && widget.scrollDirection == Axis.vertical;
    });
    expect(verticalLists, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'StorySessionDialog uses horizontal swipe for more than 2 badges',
    (tester) async {
      final summary = StorySessionSummary(
        gymId: 'g1',
        userId: 'u1',
        dayKey: '2026-02-14',
        totalXp: 50,
        generatedAt: DateTime.utc(2026, 2, 14, 20, 0),
        achievements: const [
          StoryAchievement(
            type: StoryAchievementType.newDevice,
            deviceName: 'Kniebeuge',
          ),
          StoryAchievement(
            type: StoryAchievementType.newDevice,
            deviceName: 'Bankdruecken',
          ),
          StoryAchievement(
            type: StoryAchievementType.newDevice,
            deviceName: 'Chest Fly',
          ),
        ],
        stats: const StorySessionStats(
          exerciseCount: 3,
          setCount: 8,
          durationMs: 42 * 1000,
        ),
        dailyXp: const StoryDailyXp(
          xp: 50,
          components: [StoryXpComponent(code: 'base_daily', amount: 50)],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: StorySessionDialog(summary: summary)),
        ),
      );
      await tester.pumpAndSettle();

      final horizontalLists = find.byWidgetPredicate((widget) {
        return widget is ListView && widget.scrollDirection == Axis.horizontal;
      });
      expect(horizontalLists, findsOneWidget);
      expect(find.text('+1'), findsNothing);
    },
  );
}
