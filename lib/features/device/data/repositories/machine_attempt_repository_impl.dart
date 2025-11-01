import '../../domain/models/leaderboard_entry.dart';
import '../../domain/models/machine_attempt.dart';
import '../../domain/repositories/machine_attempt_repository.dart';
import '../../domain/utils/leaderboard_time_utils.dart';
import '../sources/firestore_machine_attempt_source.dart';

class MachineAttemptRepositoryImpl implements MachineAttemptRepository {
  final FirestoreMachineAttemptSource _source;

  MachineAttemptRepositoryImpl({FirestoreMachineAttemptSource? source})
      : _source = source ?? FirestoreMachineAttemptSource();

  @override
  Future<List<MachineAttempt>> fetchTopAttempts({
    required String gymId,
    required String machineId,
    required LeaderboardTimeRange range,
    LeaderboardGenderFilter genderFilter = LeaderboardGenderFilter.all,
    int limit = 3,
  }) async {
    final dtos = await _source.fetchAttempts(
      gymId: gymId,
      machineId: machineId,
      startUtc: range.startUtc,
      endUtc: range.endUtc,
      limit: limit,
    );
    final attempts = dtos.map((dto) => dto.toDomain()).where((attempt) {
      switch (genderFilter) {
        case LeaderboardGenderFilter.female:
          return attempt.gender == 'w';
        case LeaderboardGenderFilter.male:
          return attempt.gender == 'm';
        case LeaderboardGenderFilter.all:
          return true;
      }
    }).toList();

    return attempts;
  }
}
