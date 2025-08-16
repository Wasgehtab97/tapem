import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';

void main() {
  testWidgets('Overlay keypad inputs and backspace works', (tester) async {
    final controller = OverlayNumericKeypadController();
    final textCtrl = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: OverlayNumericKeypadHost(
          controller: controller,
          child: TextField(controller: textCtrl),
        ),
      ),
    );

    controller.openFor(textCtrl);
    await tester.pumpAndSettle();

    expect(find.byType(OverlayNumericKeypad), findsOneWidget);

    // viewInsets.bottom should stay at 0 while overlay is visible
    final hostCtx = tester.element(find.byType(OverlayNumericKeypadHost));
    expect(MediaQuery.of(hostCtx).viewInsets.bottom, 0);

    await tester.tap(find.text('1'));
    await tester.pump();
    expect(textCtrl.text, '1');

    await tester.tap(find.byIcon(Icons.backspace_outlined).first);
    await tester.pump();
    expect(textCtrl.text, '');

    await tester.tap(find.byIcon(Icons.keyboard_hide_rounded));
    await tester.pumpAndSettle();
    expect(controller.isOpen, false);
  });

  testWidgets('allowDecimal parameter sets controller flag', (tester) async {
    final controller = OverlayNumericKeypadController();
    final textCtrl = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: OverlayNumericKeypadHost(
          controller: controller,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    controller.openFor(textCtrl, allowDecimal: false);
    await tester.pump();

    expect(controller.allowDecimal, false);
  });

  testWidgets('outside tap triggers button and closes keypad', (tester) async {
    final controller = OverlayNumericKeypadController();
    bool pressed = false;
    final textCtrl = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: OverlayNumericKeypadHost(
          controller: controller,
          child: Scaffold(
            body: Column(
              children: [
                TextField(controller: textCtrl, readOnly: true, onTap: () {
                  controller.openFor(textCtrl);
                }),
                TextButton(
                  onPressed: () => pressed = true,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    controller.openFor(textCtrl);
    await tester.pumpAndSettle();
    expect(controller.isOpen, true);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(pressed, false);
    expect(controller.isOpen, false);
  });
}

