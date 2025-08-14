import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/timer/session_timer_bar.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Play restarts from selected duration', (tester) async {
    await tester.pumpWidget(
        _wrap(const SessionTimerBar(initialDuration: Duration(seconds: 60))));

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:59'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    expect(find.text('01:00'), findsOneWidget);
  });

  testWidgets('Plus and minus clamp to allowed durations', (tester) async {
    await tester.pumpWidget(
        _wrap(const SessionTimerBar(initialDuration: Duration(seconds: 90))));
    final plus = find.byIcon(Icons.add);
    final minus = find.byIcon(Icons.remove);

    expect(find.text('90 s'), findsOneWidget);
    await tester.tap(plus);
    await tester.pump();
    expect(find.text('120 s'), findsOneWidget);

    await tester.tap(plus);
    await tester.pump();
    await tester.tap(plus);
    await tester.pump();
    expect(find.text('180 s'), findsOneWidget);

    await tester.tap(plus);
    await tester.pump();
    expect(find.text('180 s'), findsOneWidget);

    await tester.tap(minus);
    await tester.pump();
    await tester.tap(minus);
    await tester.pump();
    await tester.tap(minus);
    await tester.pump();
    await tester.tap(minus);
    await tester.pump();
    expect(find.text('60 s'), findsOneWidget);

    await tester.tap(minus);
    await tester.pump();
    expect(find.text('60 s'), findsOneWidget);
  });

  testWidgets('Changing duration does not affect running timer', (tester) async {
    await tester.pumpWidget(
        _wrap(const SessionTimerBar(initialDuration: Duration(seconds: 60))));

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:59'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('00:59'), findsOneWidget);
  });

  testWidgets('Timer cleans up on unmount', (tester) async {
    await tester.pumpWidget(
        _wrap(const SessionTimerBar(initialDuration: Duration(seconds: 60))));

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('close button is not rendered', (tester) async {
    await tester.pumpWidget(
        _wrap(const SessionTimerBar(initialDuration: Duration(seconds: 60))));
    expect(find.byIcon(Icons.close), findsNothing);
  });
}
