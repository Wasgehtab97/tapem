import '../models/leaderboard_entry.dart';
import '../models/machine_attempt.dart';
import '../repositories/machine_attempt_repository.dart';
import '../utils/leaderboard_time_utils.dart';

class LeaderboardService {
  final MachineAttemptRepository _repository;

  const LeaderboardService({required MachineAttemptRepository repository})
      : _repository = repository;

  Future<List<LeaderboardEntry>> loadLeaderboard({
    required String gymId,
    required String machineId,
    required LeaderboardPeriod period,
    LeaderboardGenderFilter genderFilter = LeaderboardGenderFilter.all,
    LeaderboardScoreMode mode = LeaderboardScoreMode.absolute,
    int limit = 3,
  }) async {
    final range = resolveTimeRangeUtc(period);
    final attempts = await _repository.fetchTopAttempts(
      gymId: gymId,
      machineId: machineId,
      range: range,
      genderFilter: genderFilter,
      limit: limit,
    );

    final filtered = attempts
        .where((attempt) => !attempt.isMulti)
        .where((attempt) => _hasScore(attempt, mode))
        .toList();

    filtered.sort((a, b) {
      final scoreA = _scoreForAttempt(a, mode);
      final scoreB = _scoreForAttempt(b, mode);
      return scoreB.compareTo(scoreA);
    });

    return filtered
        .take(limit)
        .map((attempt) => LeaderboardEntry(
              attempt: attempt,
              score: _scoreForAttempt(attempt, mode),
              mode: mode,
            ))
        .toList();
  }

  bool _hasScore(MachineAttempt attempt, LeaderboardScoreMode mode) {
    if (mode == LeaderboardScoreMode.absolute) {
      return attempt.e1rm > 0;
    }
    return attempt.bodyWeightKg != null && attempt.bodyWeightKg! > 0;
  }

  double _scoreForAttempt(MachineAttempt attempt, LeaderboardScoreMode mode) {
    if (mode == LeaderboardScoreMode.absolute) {
      return attempt.e1rm;
    }
    if (attempt.bodyWeightKg == null || attempt.bodyWeightKg! <= 0) {
      return 0;
    }
    return attempt.e1rm / attempt.bodyWeightKg!;
  }
}
