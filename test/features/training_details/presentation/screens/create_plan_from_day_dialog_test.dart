import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/training_details/presentation/screens/training_details_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';

void main() {
  Future<ValueNotifier<String?>> pumpDialogLauncher(WidgetTester tester) async {
    final result = ValueNotifier<String?>(null);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog<String>(
                  context: context,
                  builder: (_) => const CreatePlanFromDayDialog(),
                ).then((value) => result.value = value);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    return result;
  }

  testWidgets('enables confirm only for valid name and returns trimmed value', (
    tester,
  ) async {
    final result = await pumpDialogLauncher(tester);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final initialButton = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(initialButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  Pull Freestyle  ');
    await tester.pump();

    final enabledButton = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(enabledButton.onPressed, isNotNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byType(CreatePlanFromDayDialog), findsNothing);
    expect(result.value, 'Pull Freestyle');
  });

  testWidgets('keeps confirm disabled when name exceeds 60 chars', (
    tester,
  ) async {
    await pumpDialogLauncher(tester);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'x' * 61);
    await tester.pump();

    final disabledButton = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(disabledButton.onPressed, isNull);
  });
}
