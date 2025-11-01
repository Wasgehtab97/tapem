import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/device/domain/models/machine_attempt.dart';
import 'package:tapem/features/device/domain/repositories/machine_attempt_repository.dart';
import 'package:tapem/features/device/domain/services/leaderboard_service.dart';
import 'package:tapem/features/device/domain/utils/leaderboard_time_utils.dart';

class _FakeRepository implements MachineAttemptRepository {
  _FakeRepository(this._attempts);

  final List<MachineAttempt> _attempts;

  @override
  Future<List<MachineAttempt>> fetchTopAttempts({
    required String gymId,
    required String machineId,
    required LeaderboardTimeRange range,
    LeaderboardGenderFilter genderFilter = LeaderboardGenderFilter.all,
    int limit = 3,
  }) async {
    return _attempts.where((attempt) {
      switch (genderFilter) {
        case LeaderboardGenderFilter.female:
          return attempt.gender == 'w';
        case LeaderboardGenderFilter.male:
          return attempt.gender == 'm';
        case LeaderboardGenderFilter.all:
          return true;
      }
    }).toList();
  }
}

MachineAttempt _attempt({
  required String id,
  required double e1rm,
  double? bodyWeight,
  bool isMulti = false,
  String? gender,
}) {
  return MachineAttempt(
    id: id,
    gymId: 'gym',
    machineId: 'machine',
    userId: 'user-$id',
    username: 'User $id',
    e1rm: e1rm,
    createdAt: DateTime.utc(2024, 1, 1),
    isMulti: isMulti,
    bodyWeightKg: bodyWeight,
    gender: gender,
  );
}

void main() {
  group('LeaderboardService', () {
    test('relative scores skip invalid body weights and sort descending', () async {
      final repository = _FakeRepository([
        _attempt(id: 'a', e1rm: 180, bodyWeight: 90),
        _attempt(id: 'b', e1rm: 150, bodyWeight: null),
        _attempt(id: 'c', e1rm: 140, bodyWeight: 60),
        _attempt(id: 'd', e1rm: 100, bodyWeight: 0),
        _attempt(id: 'e', e1rm: 160, bodyWeight: 65),
        _attempt(id: 'multi', e1rm: 200, bodyWeight: 80, isMulti: true),
      ]);
      final service = LeaderboardService(repository: repository);

      final entries = await service.loadLeaderboard(
        gymId: 'gym',
        machineId: 'machine',
        period: LeaderboardPeriod.today,
        mode: LeaderboardScoreMode.relative,
        limit: 3,
      );

      expect(entries, hasLength(3));
      expect(entries.first.attempt.id, 'c');
      expect(entries.first.score, closeTo(140 / 60, 0.0001));
      expect(entries[1].attempt.id, 'e');
      expect(entries[2].attempt.id, 'a');
    });

    test('absolute mode ignores non-positive lifts', () async {
      final repository = _FakeRepository([
        _attempt(id: 'a', e1rm: 180, bodyWeight: 90),
        _attempt(id: 'b', e1rm: 0, bodyWeight: 80),
        _attempt(id: 'c', e1rm: 200, bodyWeight: 95),
      ]);
      final service = LeaderboardService(repository: repository);

      final entries = await service.loadLeaderboard(
        gymId: 'gym',
        machineId: 'machine',
        period: LeaderboardPeriod.today,
        mode: LeaderboardScoreMode.absolute,
        limit: 5,
      );

      expect(entries, hasLength(2));
      expect(entries.first.attempt.id, 'c');
      expect(entries[1].attempt.id, 'a');
    });
  });
}
