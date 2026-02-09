import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
