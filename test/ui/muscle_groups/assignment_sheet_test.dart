import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/features/muscle_group/presentation/widgets/device_muscle_assignment_sheet.dart';

class FakeMuscleGroupProvider extends ChangeNotifier implements MuscleGroupProvider {
  final List<MuscleGroup> _groups;
  List<String>? lastPrimary;
  List<String>? lastSecondary;
  MuscleRegion? ensuredRegion;

  FakeMuscleGroupProvider(this._groups);

  @override
  bool get isLoading => false;
  @override
  String? get error => null;
  @override
  List<MuscleGroup> get groups => _groups;
  @override
  Map<String, int> get counts => {};

  @override
  Future<void> loadGroups(BuildContext context) async {}

  @override
  Future<String?> ensureRegionGroup(BuildContext context, MuscleRegion region) async {
    ensuredRegion = region;
    return '${region.name}-id';
  }

  @override
  Future<void> updateDeviceAssignments(BuildContext context, String deviceId,
      List<String> primaryGroupIds, List<String> secondaryGroupIds) async {
    lastPrimary = primaryGroupIds;
    lastSecondary = secondaryGroupIds;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _openSheet(WidgetTester tester, MuscleGroupProvider prov) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<MuscleGroupProvider>.value(
      value: prov,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => const DeviceMuscleAssignmentSheet(
                    deviceId: 'd1',
                    deviceName: 'Device',
                    initialPrimary: [],
                    initialSecondary: [],
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows six unique primary options with arms and core', (tester) async {
    final prov = FakeMuscleGroupProvider([
      MuscleGroup(id: 'c1', name: 'Chest', region: MuscleRegion.chest),
      MuscleGroup(id: 'c2', name: 'Pecs', region: MuscleRegion.chest),
      MuscleGroup(id: 'b1', name: 'Back', region: MuscleRegion.back),
      MuscleGroup(id: 'b2', name: 'Back2', region: MuscleRegion.back),
      MuscleGroup(id: 's1', name: 'Shoulders', region: MuscleRegion.shoulders),
      MuscleGroup(id: 'l1', name: 'Legs', region: MuscleRegion.legs),
      MuscleGroup(id: 'a1', name: 'Arms', region: MuscleRegion.arms),
      MuscleGroup(id: 'co1', name: 'Core', region: MuscleRegion.core),
    ]);

    await _openSheet(tester, prov);

    expect(find.byType(Radio), findsNWidgets(6));
    expect(find.bySemanticsLabel('Arms, primär auswählen'), findsOneWidget);
    expect(find.bySemanticsLabel('Core, primär auswählen'), findsOneWidget);
    expect(find.bySemanticsLabel('Chest, primär auswählen'), findsOneWidget);
    expect(find.bySemanticsLabel('Back, primär auswählen'), findsOneWidget);
  });

  testWidgets('saving creates missing region and assigns', (tester) async {
    final prov = FakeMuscleGroupProvider([
      MuscleGroup(id: 'c1', name: 'Chest', region: MuscleRegion.chest),
    ]);

    await _openSheet(tester, prov);

    await tester.tap(find.bySemanticsLabel('Arms, primär auswählen'));
    await tester.pump();

    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(prov.ensuredRegion, MuscleRegion.arms);
    expect(prov.lastPrimary, ['arms-id']);
    expect(prov.lastSecondary, isEmpty);
  });

  testWidgets('reset clears assignments', (tester) async {
    final prov = FakeMuscleGroupProvider([
      MuscleGroup(id: 'c1', name: 'Chest', region: MuscleRegion.chest),
    ]);

    await _openSheet(tester, prov);

    await tester.tap(find.text('Zurücksetzen'));
    await tester.pumpAndSettle();

    expect(prov.lastPrimary, isEmpty);
    expect(prov.lastSecondary, isEmpty);
    expect(find.byType(DeviceMuscleAssignmentSheet), findsNothing);
  });
}
