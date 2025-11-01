import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/device/data/dtos/machine_attempt_dto.dart';
import 'package:tapem/features/device/data/repositories/machine_attempt_repository_impl.dart';
import 'package:tapem/features/device/data/sources/firestore_machine_attempt_source.dart';
import 'package:tapem/features/device/domain/models/leaderboard_entry.dart';
import 'package:tapem/features/device/domain/utils/leaderboard_time_utils.dart';

class _FakeSource extends FirestoreMachineAttemptSource {
  _FakeSource(this._attempts);

  final List<MachineAttemptDto> _attempts;

  @override
  Future<List<MachineAttemptDto>> fetchAttempts({
    required String gymId,
    required String machineId,
    required DateTime startUtc,
    required DateTime endUtc,
    int limit = 3,
  }) async {
    return _attempts;
  }
}

MachineAttemptDto _dto({
  required String id,
  String? gender,
}) {
  return MachineAttemptDto(
    id: id,
    gymId: 'gym',
    machineId: 'machine',
    userId: 'user-$id',
    username: 'User $id',
    e1rm: 100,
    createdAt: DateTime.utc(2024, 1, 1),
    isMulti: false,
    gender: gender,
  );
}

void main() {
  group('MachineAttemptRepositoryImpl', () {
    final range = LeaderboardTimeRange(
      startUtc: DateTime.utc(2024, 1, 1),
      endUtc: DateTime.utc(2024, 1, 2),
    );

    test('returns all attempts when filter is all', () async {
      final repository = MachineAttemptRepositoryImpl(
        source: _FakeSource([
          _dto(id: 'a', gender: 'w'),
          _dto(id: 'b', gender: 'm'),
          _dto(id: 'c', gender: null),
        ]),
      );

      final attempts = await repository.fetchTopAttempts(
        gymId: 'gym',
        machineId: 'machine',
        range: range,
        genderFilter: LeaderboardGenderFilter.all,
        limit: 3,
      );

      expect(attempts.map((a) => a.id), ['a', 'b', 'c']);
    });

    test('filters attempts for female leaderboard', () async {
      final repository = MachineAttemptRepositoryImpl(
        source: _FakeSource([
          _dto(id: 'a', gender: 'w'),
          _dto(id: 'b', gender: 'm'),
          _dto(id: 'c', gender: 'w'),
        ]),
      );

      final attempts = await repository.fetchTopAttempts(
        gymId: 'gym',
        machineId: 'machine',
        range: range,
        genderFilter: LeaderboardGenderFilter.female,
        limit: 3,
      );

      expect(attempts.map((a) => a.id), ['a', 'c']);
    });

    test('filters attempts for male leaderboard', () async {
      final repository = MachineAttemptRepositoryImpl(
        source: _FakeSource([
          _dto(id: 'a', gender: 'w'),
          _dto(id: 'b', gender: 'm'),
          _dto(id: 'c', gender: null),
          _dto(id: 'd', gender: 'm'),
        ]),
      );

      final attempts = await repository.fetchTopAttempts(
        gymId: 'gym',
        machineId: 'machine',
        range: range,
        genderFilter: LeaderboardGenderFilter.male,
        limit: 3,
      );

      expect(attempts.map((a) => a.id), ['b', 'd']);
    });
  });
}
