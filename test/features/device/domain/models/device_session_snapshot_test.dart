import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';

void main() {
  test('DeviceSessionSnapshot serialization', () {
    final snapshot = DeviceSessionSnapshot(
      sessionId: 's1',
      deviceId: 'd1',
      exerciseId: 'e1',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      note: 'note',
      sets: const [
        SetEntry(
          kg: 20,
          reps: 10,
          rir: 2,
          done: true,
          note: 'set',
          drops: [DropEntry(kg: 10, reps: 5)],
        ),
      ],
    );

    final json = snapshot.toJson();
    expect(json['sessionId'], 's1');
    expect(json['deviceId'], 'd1');
    expect((json['createdAt'] as Timestamp).millisecondsSinceEpoch, 0);

    final decoded = DeviceSessionSnapshot.fromJson(json);
    expect(decoded.sessionId, snapshot.sessionId);
    expect(decoded.sets.first.drops.first.kg, 10);
  });
}
