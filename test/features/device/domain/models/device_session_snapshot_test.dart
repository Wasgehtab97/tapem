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
      userId: 'u1',
      note: 'note',
      sets: const [
        SetEntry(
          kg: 20,
          reps: 10,
          done: true,
          drops: [DropEntry(kg: 10, reps: 5)],
        ),
        SetEntry(kg: 0, reps: 5, isBodyweight: true),
        SetEntry(speedKmH: 10, durationSec: 90, done: true),
      ],
      isCardio: true,
      mode: 'timed',
      durationSec: 90,
    );

    final json = snapshot.toJson();
    expect(json['sessionId'], 's1');
    expect(json['deviceId'], 'd1');
    expect(json['userId'], 'u1');
    expect((json['createdAt'] as Timestamp).millisecondsSinceEpoch, 0);

    final decoded = DeviceSessionSnapshot.fromJson(json);
    expect(decoded.sessionId, snapshot.sessionId);
    expect(decoded.sets.first.drops.first.kg, 10);
    expect(decoded.sets[1].isBodyweight, true);
    expect(decoded.sets[1].kg, 0);
    expect(decoded.sets[2].speedKmH, 10);
    expect(decoded.sets[2].durationSec, 90);
    expect(decoded.isCardio, true);
    expect(decoded.mode, 'timed');
    expect(decoded.durationSec, 90);
  });
}
