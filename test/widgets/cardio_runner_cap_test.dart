import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/features/device/presentation/providers/cardio_timer_provider.dart';
import 'package:tapem/features/device/presentation/widgets/cardio_runner.dart';
import 'package:tapem/l10n/app_localizations.dart';

void main() {
  testWidgets('cap reached disables save and shows hint', (tester) async {
    final timer = CardioTimerProvider();
    timer.start();
    await tester.pump(const Duration(seconds: 1));
    timer.pause();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider<CardioTimerProvider>.value(
          value: timer,
          child: CardioRunner(
            onCancel: () {},
            onSave: (_) {},
            capReached: true,
            capMessage: 'Cap',
          ),
        ),
      ),
    );

    expect(find.text('Cap'), findsOneWidget);
    final saveFinder = find.widgetWithText(ElevatedButton, 'Save');
    final btn = tester.widget<ElevatedButton>(saveFinder);
    expect(btn.onPressed, isNull);
  });
}
