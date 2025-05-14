// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/main.dart';

void main() {
  testWidgets('SplashScreen is shown on startup', (WidgetTester tester) async {
    // Our app expects providers + SplashBloc, daher pumpen wir den ganzen TapemApp-Tree:
    await tester.pumpWidget(const TapemApp());

    // initialFrame: SplashScreen zeigt CircularProgressIndicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wir lassen eine Frame-Dauer verstreichen, um BlocListener auszulösen
    // (hier simuliert, dass SplashNavigate sofort auf '/auth' oder '/home' wechselt):
    await tester.pumpAndSettle();

    // Nach Navigation sollte entweder AuthScreen oder HomeScreen da sein.
    // Wir prüfen einfach, dass kein Splash mehr zu sehen ist:
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
