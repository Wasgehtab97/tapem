import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/presentation/widgets/session_sets_table.dart';
import '../test_utils.dart';

void main() {
  testWidgets('renders header and add row', (tester) async {
    final prov = DeviceProvider(firestore: makeFirestore());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: prov,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: SessionSetsTable(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('SET'), findsOneWidget);
    expect(find.text('Add Set +'), findsOneWidget);
  });

  testWidgets('add set adds a row', (tester) async {
    final prov = DeviceProvider(firestore: makeFirestore());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: prov,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: SessionSetsTable(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add Set +'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
  });
}
