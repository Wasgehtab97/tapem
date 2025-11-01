import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/core/logging/elog.dart';
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
    if (limit <= 0) {
      return const [];
    }
    final range = resolveTimeRangeUtc(period);
    final attempts = await _fetchAttempts(
      gymId: gymId,
      machineId: machineId,
      range: range,
      genderFilter: genderFilter,
      limit: limit,
    );

    final scored = attempts
        .where((attempt) => !attempt.isMulti)
        .map((attempt) => _ScoredAttempt(
              attempt,
              _scoreForAttempt(attempt, mode),
            ))
        .where((entry) => entry.score.isFinite)
        .toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored
        .take(limit)
        .map((entry) => LeaderboardEntry(
              attempt: entry.attempt,
              score: entry.score,
              mode: mode,
            ))
        .toList();
  }

  Future<List<MachineAttempt>> _fetchAttempts({
    required String gymId,
    required String machineId,
    required LeaderboardTimeRange range,
    required LeaderboardGenderFilter genderFilter,
    required int limit,
  }) async {
    try {
      return await _repository.fetchTopAttempts(
        gymId: gymId,
        machineId: machineId,
        range: range,
        genderFilter: genderFilter,
        limit: limit,
      );
    } on FirebaseException catch (error, stack) {
      if (error.code == 'failed-precondition') {
        elogError(
          'LEADERBOARD_FIRESTORE_INDEX',
          error,
          stack,
          {
            'gymId': gymId,
            'machineId': machineId,
            'gender': genderFilter.toString(),
            'mode': 'fetch',
          },
        );
      } else {
        elogError(
          'LEADERBOARD_FIRESTORE_ERROR',
          error,
          stack,
          {
            'gymId': gymId,
            'machineId': machineId,
            'gender': genderFilter.toString(),
            'mode': 'fetch',
          },
        );
      }
      rethrow;
    } catch (error, stack) {
      elogError(
        'LEADERBOARD_FETCH_ERROR',
        error,
        stack,
        {
          'gymId': gymId,
          'machineId': machineId,
          'gender': genderFilter.toString(),
        },
      );
      rethrow;
    }
  }

  double _scoreForAttempt(MachineAttempt attempt, LeaderboardScoreMode mode) {
    if (mode == LeaderboardScoreMode.absolute) {
      return attempt.e1rm > 0 ? attempt.e1rm : double.nan;
    }
    if (attempt.bodyWeightKg == null || attempt.bodyWeightKg! <= 0) {
      return double.nan;
    }
    if (attempt.e1rm <= 0) {
      return double.nan;
    }
    return attempt.e1rm / attempt.bodyWeightKg!;
  }
}

class _ScoredAttempt {
  final MachineAttempt attempt;
  final double score;

  const _ScoredAttempt(this.attempt, this.score);
}
