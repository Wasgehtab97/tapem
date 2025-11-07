import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/presentation/widgets/note_button_widget.dart';
import 'package:tapem/l10n/app_localizations.dart';

class _MockDeviceProvider extends Mock
    with ChangeNotifier
    implements DeviceProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockDeviceProvider provider;

  setUp(() {
    provider = _MockDeviceProvider();
    when(() => provider.note).thenReturn('');
    when(() => provider.setNote(any())).thenAnswer((_) {});
  });

  Widget buildApp(NoteButtonWidget fab) {
    return ChangeNotifierProvider<DeviceProvider>.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          floatingActionButton: fab,
        ),
      ),
    );
  }

  testWidgets('saving a note forwards trimmed text to provider', (tester) async {
    when(() => provider.note).thenReturn('initial');

    await tester.pumpWidget(
      buildApp(const NoteButtonWidget(deviceId: 'd1')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), ' new note ');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    verify(() => provider.setNote('new note')).called(1);
  });

  testWidgets('deleting a note clears provider value', (tester) async {
    when(() => provider.note).thenReturn('existing');

    await tester.pumpWidget(
      buildApp(const NoteButtonWidget(deviceId: 'd1')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    verify(() => provider.setNote('')).called(1);
  });

  testWidgets('hero tag includes session key when provided', (tester) async {
    await tester.pumpWidget(
      buildApp(
        const NoteButtonWidget(
          deviceId: 'device',
          sessionIdentifier: 'session-1',
        ),
      ),
    );

    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );

    expect(fab.heroTag, 'noteBtn_device_session-1');
  });

  testWidgets('hero tag includes tuple data when session key missing', (tester) async {
    await tester.pumpWidget(
      buildApp(
        const NoteButtonWidget(
          deviceId: 'device',
          sessionIdentifier: ('device', 'exercise'),
        ),
      ),
    );

    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );

    expect(fab.heroTag, 'noteBtn_device_exercise');
  });
}
