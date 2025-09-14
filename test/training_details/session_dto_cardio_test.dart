import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/training_details/data/dtos/session_dto.dart';

void main() {
  test('cardio log without weight/reps parses', () async {
    final ff = FakeFirebaseFirestore();
    final ref = await ff
        .collection('gyms')
        .doc('g1')
        .collection('devices')
        .doc('c1')
        .collection('logs')
        .add({
      'sessionId': 's1',
      'deviceId': 'c1',
      'exerciseId': 'e1',
      'userId': 'u1',
      'timestamp': Timestamp.now(),
      'setNumber': 1,
      'note': '',
      'tz': 'UTC',
      'isCardio': true,
      'mode': 'timed',
      'durationSec': 120,
    });
    final snap = await ref.get();
    final dto = SessionDto.fromFirestore(snap);
    expect(dto.isCardio, isTrue);
    expect(dto.weight, isNull);
    expect(dto.durationSec, 120);
    expect(dto.mode, 'timed');
  });
}
