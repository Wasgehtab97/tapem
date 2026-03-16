import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';

void main() {
  testWidgets('default action rail uses 3x2 order back/next, -/+, copy/hide', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = OverlayNumericKeypadController();
    controller.openFor(TextEditingController(text: '10'), allowDecimal: true);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: OverlayNumericKeypad(
              controller: controller,
              theme: const NumericKeypadTheme(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final back = find.byIcon(Icons.arrow_back_rounded);
    final next = find.byIcon(Icons.arrow_forward_rounded);
    final minus = find.byIcon(Icons.remove_rounded);
    final plus = find.byIcon(Icons.add_rounded);
    final copy = find.byIcon(Icons.copy_all_rounded);
    final hide = find.byIcon(Icons.keyboard_hide_rounded);

    expect(back, findsOneWidget);
    expect(next, findsOneWidget);
    expect(minus, findsOneWidget);
    expect(plus, findsOneWidget);
    expect(copy, findsOneWidget);
    expect(hide, findsOneWidget);

    final backY = tester.getCenter(back).dy;
    final nextY = tester.getCenter(next).dy;
    final minusY = tester.getCenter(minus).dy;
    final plusY = tester.getCenter(plus).dy;
    final copyY = tester.getCenter(copy).dy;
    final hideY = tester.getCenter(hide).dy;

    expect((backY - nextY).abs(), lessThan(8));
    expect((minusY - plusY).abs(), lessThan(8));
    expect((copyY - hideY).abs(), lessThan(8));

    expect(minusY, greaterThan(backY + 4));
    expect(copyY, greaterThan(minusY + 4));
  });

  testWidgets('keypad does not overflow on compact screen size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = OverlayNumericKeypadController();
    controller.openFor(TextEditingController(text: '10'), allowDecimal: true);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: OverlayNumericKeypad(
              controller: controller,
              theme: const NumericKeypadTheme(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('keypad does not overflow in landscape size', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = OverlayNumericKeypadController();
    controller.openFor(TextEditingController(text: '10'), allowDecimal: true);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: OverlayNumericKeypad(
              controller: controller,
              theme: const NumericKeypadTheme(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  test('computeAdjustedFocusedValue adjusts kg with locale comma', () {
    final adjusted = OverlayNumericKeypad.computeAdjustedFocusedValue(
      field: DeviceSetFieldFocus.weight,
      currentText: '10,5',
      delta: 1,
      decimalChar: ',',
    );
    expect(adjusted, '11,5');
  });

  test('computeAdjustedFocusedValue adjusts reps and clamps to zero', () {
    final increased = OverlayNumericKeypad.computeAdjustedFocusedValue(
      field: DeviceSetFieldFocus.reps,
      currentText: '',
      delta: 1,
      decimalChar: ',',
    );
    final clamped = OverlayNumericKeypad.computeAdjustedFocusedValue(
      field: DeviceSetFieldFocus.reps,
      currentText: '0',
      delta: -1,
      decimalChar: ',',
    );

    expect(increased, '1');
    expect(clamped, '0');
  });

  test('computeAdjustedFocusedValue adjusts drop fields with dot parsing', () {
    final dropWeight = OverlayNumericKeypad.computeAdjustedFocusedValue(
      field: DeviceSetFieldFocus.dropWeight,
      currentText: '12.5',
      delta: -1,
      decimalChar: '.',
    );
    final dropReps = OverlayNumericKeypad.computeAdjustedFocusedValue(
      field: DeviceSetFieldFocus.dropReps,
      currentText: '',
      delta: 1,
      decimalChar: '.',
    );

    expect(dropWeight, '11.5');
    expect(dropReps, '1');
  });
}
