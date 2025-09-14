import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/history/data/dtos/workout_log_dto.dart';

void main() {
  test('parses cardio log without weight/reps', () {
    final dto = WorkoutLogDto.fromJson({
      'userId': 'u1',
      'sessionId': 's1',
      'timestamp': Timestamp.fromDate(DateTime(2024)),
      'setNumber': 1,
      'isCardio': true,
      'mode': 'timed',
      'durationSec': 60,
    });
    dto.id = 'l1';
    final model = dto.toModel();
    expect(model.isCardio, isTrue);
    expect(model.durationSec, 60);
    expect(model.weight, isNull);
    expect(model.reps, isNull);
  });
}
