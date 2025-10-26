import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/presentation/widgets/set_card.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';

class _MockDeviceProvider extends Mock
    with ChangeNotifier
    implements DeviceProvider {}

class _MockKeypadController extends Mock
    with ChangeNotifier
    implements OverlayNumericKeypadController {}

class _FakeTextEditingController extends Fake implements TextEditingController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeTextEditingController());
  });

  late _MockDeviceProvider provider;
  late _MockKeypadController keypad;
  late Map<String, dynamic> setData;

  setUp(() {
    provider = _MockDeviceProvider();
    keypad = _MockKeypadController();
    setData = {
      'number': '1',
      'weight': '10',
      'reps': '8',
      'done': false,
      'drops': const [],
    };

    when(() => provider.isBodyweightMode).thenReturn(false);
    when(() => provider.focusedField).thenReturn(null);
    when(() => provider.focusedIndex).thenReturn(null);
    when(() => provider.focusedDropIndex).thenReturn(null);
    when(() => provider.focusRequestId).thenReturn(0);
    when(
      () => provider.requestFocus(
        index: any(named: 'index'),
        field: any(named: 'field'),
        dropIndex: any(named: 'dropIndex'),
      ),
    ).thenReturn(0);
    when(() => provider.ensureDropSlot(any())).thenReturn(0);
    when(() => provider.addDropToSet(any())).thenReturn(0);
    when(() => provider.updateDrop(any(), any(), weight: any(named: 'weight'), reps: any(named: 'reps')))
        .thenAnswer((_) {});
    when(
      () => provider.updateSet(
        any(),
        weight: any(named: 'weight'),
        reps: any(named: 'reps'),
        dropWeight: any(named: 'dropWeight'),
        dropReps: any(named: 'dropReps'),
        isBodyweight: any(named: 'isBodyweight'),
      ),
    ).thenAnswer((_) {});
    when(() => provider.toggleSetDone(any())).thenReturn(true);
    when(() => provider.clearFocus()).thenReturn(0);
    when(() => keypad.openFor(
          any(),
          allowDecimal: any(named: 'allowDecimal'),
          decimalStep: any(named: 'decimalStep'),
          integerStep: any(named: 'integerStep'),
        )).thenAnswer((_) {});
    when(() => keypad.close()).thenAnswer((_) {});
  });

  Widget buildTestApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DeviceProvider>.value(value: provider),
        ChangeNotifierProvider<OverlayNumericKeypadController>.value(
          value: keypad,
        ),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SetCard(
            index: 0,
            set: setData,
          ),
        ),
      ),
    );
  }

  testWidgets('tapping weight field opens keypad and requests focus', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();

    verify(
      () => provider.requestFocus(
        index: 0,
        field: DeviceSetFieldFocus.weight,
        dropIndex: any(named: 'dropIndex'),
      ),
    ).called(1);
    verify(() => keypad.openFor(any(), allowDecimal: true, decimalStep: any(named: 'decimalStep'), integerStep: any(named: 'integerStep')))
        .called(1);
  });
}
