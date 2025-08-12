import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/ui/numeric_keypad/numeric_keypad.dart';

void main() {
  testWidgets('NumericKeypadTheme uses theme colors', (tester) async {
    late NumericKeypadTheme th;
    final theme = ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: Colors.red,
        surface: Colors.black,
        onPrimary: Colors.white,
      ),
      canvasColor: Colors.grey,
    );
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) {
          th = NumericKeypadTheme.fromTheme(Theme.of(context));
          return const SizedBox.shrink();
        },
      ),
    ));
    expect(th.bg, theme.colorScheme.surface);
    expect(th.keyBg, theme.canvasColor);
    expect(th.cta, theme.colorScheme.primary);
  });
}
