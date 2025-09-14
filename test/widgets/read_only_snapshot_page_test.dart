import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'package:tapem/features/device/presentation/widgets/read_only_snapshot_page.dart';

void main() {
  testWidgets('shows drop mini cards under main set', (tester) async {
    final snapshot = DeviceSessionSnapshot(
      sessionId: 's1',
      deviceId: 'd1',
      createdAt: DateTime(2024),
      userId: 'u1',
      sets: const [
        SetEntry(kg: 80, reps: 8),
        SetEntry(kg: 70, reps: 8, drops: [DropEntry(kg: 11, reps: 1)]),
      ],
    );
    await tester.pumpWidget(MaterialApp(home: ReadOnlySnapshotPage(snapshot: snapshot)));
    expect(find.text('11 kg'), findsOneWidget);
    expect(find.text('1 ×'), findsOneWidget);
  });

  testWidgets('renders cardio set with formatted duration', (tester) async {
    final snapshot = DeviceSessionSnapshot(
      sessionId: 's1',
      deviceId: 'd1',
      createdAt: DateTime(2024),
      userId: 'u1',
      sets: const [SetEntry(speedKmH: 10, durationSec: 90)],
    );
    await tester.pumpWidget(
      MaterialApp(home: ReadOnlySnapshotPage(snapshot: snapshot)),
    );
    expect(find.text('10'), findsOneWidget);
    expect(find.text('00:01:30'), findsOneWidget);
  });

  testWidgets('renders timed cardio session summary', (tester) async {
    final snapshot = DeviceSessionSnapshot(
      sessionId: 's2',
      deviceId: 'd1',
      createdAt: DateTime(2024),
      userId: 'u1',
      sets: const [],
      isCardio: true,
      mode: 'timed',
      durationSec: 65,
    );
    await tester.pumpWidget(
      MaterialApp(home: ReadOnlySnapshotPage(snapshot: snapshot)),
    );
    expect(find.textContaining('00:01:05'), findsOneWidget);
  });

  testWidgets('renders steady cardio snapshot', (tester) async {
    final snapshot = DeviceSessionSnapshot(
      sessionId: 's3',
      deviceId: 'd1',
      createdAt: DateTime(2024),
      userId: 'u1',
      sets: const [SetEntry(speedKmH: 8, durationSec: 120)],
      isCardio: true,
      mode: 'steady',
      durationSec: 120,
      speedKmH: 8,
    );
    await tester.pumpWidget(
      MaterialApp(home: ReadOnlySnapshotPage(snapshot: snapshot)),
    );
    expect(find.textContaining('8.0 km/h'), findsOneWidget);
    expect(find.textContaining('00:02:00'), findsOneWidget);
  });

  testWidgets('renders interval cardio snapshot', (tester) async {
    final snapshot = DeviceSessionSnapshot(
      sessionId: 's4',
      deviceId: 'd1',
      createdAt: DateTime(2024),
      userId: 'u1',
      sets: const [
        SetEntry(speedKmH: 8, durationSec: 60),
        SetEntry(speedKmH: 10, durationSec: 90),
      ],
      isCardio: true,
      mode: 'intervals',
      durationSec: 150,
    );
    await tester.pumpWidget(
      MaterialApp(home: ReadOnlySnapshotPage(snapshot: snapshot)),
    );
    expect(find.textContaining('00:01:00'), findsOneWidget);
    expect(find.textContaining('00:01:30'), findsOneWidget);
  });
}
