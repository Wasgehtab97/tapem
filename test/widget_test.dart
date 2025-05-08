// test/widget_test.dart


import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/main.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TapemApp());

    // Prüfe: Der Title-Text (APP_NAME aus .env) wird angezeigt.
    expect(find.text('Tap\'em'), findsOneWidget);
  });
}
