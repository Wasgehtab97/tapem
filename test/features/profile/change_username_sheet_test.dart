import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/profile/presentation/widgets/change_username_sheet.dart';
import 'package:tapem/l10n/app_localizations.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  Future<void> _openSheet(WidgetTester tester, AuthProvider auth) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showChangeUsernameSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('typing a valid new username enables save', (tester) async {
    final auth = MockAuthProvider();
    when(() => auth.userName).thenReturn('current');
    when(() => auth.checkUsernameAvailable(any())).thenAnswer((_) async => true);
    when(() => auth.setUsername(any())).thenAnswer((_) async => true);
    when(() => auth.error).thenReturn(null);

    await _openSheet(tester, auth);

    await tester.enterText(find.byType(TextField), 'new name');
    await tester.pump(const Duration(milliseconds: 600));

    final saveFinder = find.widgetWithText(ElevatedButton, 'Speichern');
    final button = tester.widget<ElevatedButton>(saveFinder);
    expect(button.onPressed, isNotNull);
  });

  testWidgets('same username keeps save disabled', (tester) async {
    final auth = MockAuthProvider();
    when(() => auth.userName).thenReturn('current');
    when(() => auth.checkUsernameAvailable(any())).thenAnswer((_) async => true);
    when(() => auth.setUsername(any())).thenAnswer((_) async => true);
    when(() => auth.error).thenReturn(null);

    await _openSheet(tester, auth);

    await tester.enterText(find.byType(TextField), 'Current');
    await tester.pump(const Duration(milliseconds: 600));

    final saveFinder = find.widgetWithText(ElevatedButton, 'Speichern');
    final button = tester.widget<ElevatedButton>(saveFinder);
    expect(button.onPressed, isNull);
  });
}
