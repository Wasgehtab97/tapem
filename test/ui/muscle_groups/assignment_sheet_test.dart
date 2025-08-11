import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/features/muscle_group/presentation/widgets/device_muscle_assignment_sheet.dart';
import 'package:tapem/l10n/app_localizations.dart';

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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
  testWidgets('tab counts update and exclusivity', (tester) async {
    final prov = FakeMuscleGroupProvider([
      MuscleGroup(id: 'c1', name: 'Chest', region: MuscleRegion.chest),
      MuscleGroup(id: 'c2', name: 'Pecs', region: MuscleRegion.chest),
      MuscleGroup(id: 'b1', name: 'Lats', region: MuscleRegion.lats),
      MuscleGroup(id: 'b2', name: 'Mid Back', region: MuscleRegion.midBack),
      MuscleGroup(id: 's1', name: 'Anterior Deltoid', region: MuscleRegion.anteriorDeltoid),
      MuscleGroup(id: 'l1', name: 'Quadriceps', region: MuscleRegion.quadriceps),
      MuscleGroup(id: 'a1', name: 'Biceps', region: MuscleRegion.biceps),
      MuscleGroup(id: 'co1', name: 'Rectus Abdominis', region: MuscleRegion.rectusAbdominis),
    ]);

    await _openSheet(tester, prov);

    // initially counts 0 / 0
    expect(find.text('Primary (0)'), findsOneWidget);
    expect(find.text('Secondary (0)'), findsOneWidget);

    // select a primary
    await tester.tap(find.text('Biceps').first);
    await tester.pump();
    expect(find.text('Primary (1)'), findsOneWidget);

    // switch to secondary tab and select two
    await tester.tap(find.text('Secondary (0)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lats').first);
    await tester.pump();
    await tester.tap(find.text('Mid Back').first);
    await tester.pump();
    expect(find.text('Secondary (2)'), findsOneWidget);

    // selecting primary removes from secondary
    await tester.tap(find.text('Primary (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lats').first);
    await tester.pump();
    expect(find.text('Secondary (1)'), findsOneWidget);
  });

  testWidgets('saving creates missing region and assigns', (tester) async {
    final prov = FakeMuscleGroupProvider([
      MuscleGroup(id: 'c1', name: 'Chest', region: MuscleRegion.chest),
    ]);

    await _openSheet(tester, prov);

    await tester.tap(find.text('Biceps').first);
    await tester.pump();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(prov.ensuredRegion, MuscleRegion.biceps);
    expect(prov.lastPrimary, ['biceps-id']);
    expect(prov.lastSecondary, isEmpty);
  });

  testWidgets('reset clears assignments', (tester) async {
    final prov = FakeMuscleGroupProvider([
      MuscleGroup(id: 'c1', name: 'Chest', region: MuscleRegion.chest),
    ]);

    await _openSheet(tester, prov);

    await tester.tap(find.text('Reset'));
    await tester.pump();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(prov.lastPrimary, isEmpty);
    expect(prov.lastSecondary, isEmpty);
    expect(find.byType(DeviceMuscleAssignmentSheet), findsNothing);
  });
}
