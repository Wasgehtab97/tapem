import '../models/machine_attempt.dart';
import '../utils/leaderboard_time_utils.dart';
import '../models/leaderboard_entry.dart';

typedef MachineAttemptList = List<MachineAttempt>;

abstract class MachineAttemptRepository {
  Future<MachineAttemptList> fetchTopAttempts({
    required String gymId,
    required String machineId,
    required LeaderboardTimeRange range,
    LeaderboardGenderFilter genderFilter = LeaderboardGenderFilter.all,
    int limit = 3,
  });
}
