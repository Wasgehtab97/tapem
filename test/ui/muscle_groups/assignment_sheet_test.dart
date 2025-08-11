import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/features/muscle_group/presentation/widgets/device_muscle_assignment_sheet.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';

class FakeMuscleGroupProvider extends ChangeNotifier
    implements MuscleGroupProvider {
  final List<MuscleGroup> _groups;
  String? lastDeviceId;
  List<String>? lastPrimary;
  List<String>? lastSecondary;

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
  Future<void> updateDeviceAssignments(BuildContext context, String deviceId,
      List<String> primaryGroupIds, List<String> secondaryGroupIds) async {
    lastDeviceId = deviceId;
    lastPrimary = primaryGroupIds;
    lastSecondary = secondaryGroupIds;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('toggling and saving calls updateDeviceAssignments',
      (tester) async {
    final prov = FakeMuscleGroupProvider([
      MuscleGroup(
        id: 'm1',
        name: 'Chest',
        region: MuscleRegion.chest,
        primaryDeviceIds: const [],
        secondaryDeviceIds: const [],
        exerciseIds: const [],
      ),
      MuscleGroup(
        id: 'm2',
        name: 'Back',
        region: MuscleRegion.back,
        primaryDeviceIds: const [],
        secondaryDeviceIds: const [],
        exerciseIds: const [],
      ),
    ]);

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

    await tester.tap(find.widgetWithText(FilterChip, 'Chest').first);
    await tester.pump();

    await tester.tap(find.widgetWithText(FilterChip, 'Back').last);
    await tester.pump();

    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(prov.lastDeviceId, 'd1');
    expect(prov.lastPrimary, ['m1']);
    expect(prov.lastSecondary, ['m2']);
  });
}
