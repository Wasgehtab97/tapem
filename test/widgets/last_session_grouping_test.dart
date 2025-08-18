import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/device/presentation/models/session_set_vm.dart';
import 'package:tapem/features/device/presentation/widgets/last_session_card.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';

void main() {
  testWidgets('drop is rendered under its main set', (tester) async {
    final sets = [
      const SessionSetVM(ordinal: 1, kg: 50, reps: 5),
      SessionSetVM(
        ordinal: 2,
        kg: 40,
        reps: 5,
        drops: const [DropEntry(kg: 11, reps: 1)],
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LastSessionCard(date: DateTime(2024), sets: sets),
        ),
      ),
    );
    expect(find.text('11 kg × 1'), findsOneWidget);
  });
}
