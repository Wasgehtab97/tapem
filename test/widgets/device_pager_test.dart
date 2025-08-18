import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/presentation/widgets/device_pager.dart';

class _FakeDeviceRepository implements DeviceRepository {
  final List<DeviceSessionSnapshot> snaps;
  _FakeDeviceRepository(this.snaps);

  @override
  Future<List<DeviceSessionSnapshot>> fetchSessionSnapshotsPaginated({
    required String gymId,
    required String deviceId,
    required String userId,
    required int limit,
    DocumentSnapshot? startAfter,
  }) async => snaps;

  @override
  DocumentSnapshot? get lastSnapshotCursor => null;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('pager direction and swipe handlers', (tester) async {
    final snapshot = DeviceSessionSnapshot(
      sessionId: 's1',
      deviceId: 'd1',
      createdAt: DateTime(2023, 1, 1),
      userId: 'u1',
      note: 'snapnote',
      sets: const [SetEntry(kg: 10, reps: 5)],
    );
    final repo = _FakeDeviceRepository([snapshot]);
    final prov = DeviceProvider(
      firestore: FakeFirebaseFirestore(),
      deviceRepository: repo,
    );
    await prov.loadMoreSnapshots(gymId: 'g', deviceId: 'd', userId: 'u1');

    await tester.pumpWidget(MaterialApp(
      home: DevicePager(
        editablePage: const Text('edit'),
        provider: prov,
        gymId: 'g',
        deviceId: 'd',
        userId: 'u1',
      ),
    ));

    expect(find.text('edit'), findsOneWidget);

    await tester.tap(find.byTooltip('Vorherige Session'));
    await tester.pumpAndSettle();
    expect(find.text('snapnote'), findsOneWidget);

    await tester.tap(find.byTooltip('Neuere / Aktuelle'));
    await tester.pumpAndSettle();
    expect(find.text('edit'), findsOneWidget);

    await tester.dragFrom(const Offset(5, 300), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.text('snapnote'), findsOneWidget);

    await tester.dragFrom(const Offset(300, 300), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('edit'), findsOneWidget);
  });
}
