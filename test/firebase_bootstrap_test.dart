import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tapem/bootstrap/firebase_bootstrap.dart';

void main() {
  testWidgets('firebase bootstrap initializes only one app', (tester) async {
    final first = await firebaseBootstrap();
    expect(Firebase.apps.length, 1);

    final second = await firebaseBootstrap();
    expect(Firebase.apps.length, 1);
    expect(identical(first.app, second.app), isTrue);
  });
}
