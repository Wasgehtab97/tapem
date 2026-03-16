import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/training_details/data/models/hive_session.dart';
import 'package:tapem/features/training_details/data/repositories/session_repository_impl.dart';

HiveSession _session({
  required String sessionId,
  required DateTime timestamp,
  DateTime? startTime,
  DateTime? endTime,
  DateTime? updatedAt,
}) {
  return HiveSession()
    ..sessionId = sessionId
    ..gymId = 'gym-1'
    ..userId = 'user-1'
    ..deviceId = 'device-1'
    ..deviceName = 'Device'
    ..deviceDescription = ''
    ..isMulti = false
    ..exerciseId = 'ex-1'
    ..exerciseName = 'Exercise'
    ..timestamp = timestamp
    ..note = ''
    ..sets = <HiveSessionSet>[]
    ..startTime = startTime
    ..endTime = endTime
    ..durationMs = null
    ..updatedAt = updatedAt ?? timestamp;
}

void main() {
  test(
    'keeps chronological order when sessions share same start timestamp',
    () {
      final commonStart = DateTime.utc(2026, 3, 15, 19, 0, 0);
      final shoulderPress = _session(
        sessionId: 'shoulder',
        timestamp: commonStart,
        startTime: commonStart,
        endTime: DateTime.utc(2026, 3, 15, 19, 12, 0),
        updatedAt: DateTime.utc(2026, 3, 15, 19, 12, 1),
      );
      final lateralRaise = _session(
        sessionId: 'lateral',
        timestamp: commonStart,
        startTime: commonStart,
        endTime: DateTime.utc(2026, 3, 15, 19, 20, 0),
        updatedAt: DateTime.utc(2026, 3, 15, 19, 20, 1),
      );

      final sessions = <HiveSession>[lateralRaise, shoulderPress]
        ..sort(compareSessionsForDayOrder);

      expect(sessions.map((s) => s.sessionId), <String>['shoulder', 'lateral']);
    },
  );

  test(
    'uses updatedAt and sessionId as deterministic fallback tie breakers',
    () {
      final anchor = DateTime.utc(2026, 3, 15, 19, 0, 0);
      final a = _session(
        sessionId: 'a',
        timestamp: anchor,
        startTime: anchor,
        endTime: anchor,
        updatedAt: DateTime.utc(2026, 3, 15, 19, 5, 0),
      );
      final b = _session(
        sessionId: 'b',
        timestamp: anchor,
        startTime: anchor,
        endTime: anchor,
        updatedAt: DateTime.utc(2026, 3, 15, 19, 5, 1),
      );

      final sessions = <HiveSession>[b, a]..sort(compareSessionsForDayOrder);

      expect(sessions.map((s) => s.sessionId), <String>['a', 'b']);
    },
  );
}
