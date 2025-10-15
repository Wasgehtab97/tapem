import 'device_xp_result.dart';
import 'xp_limits.dart';
import 'xp_paged_result.dart';

abstract class XpRepository {
  Future<DeviceXpResult> addSessionXp({
    required String gymId,
    required String userId,
    required String deviceId,
    required String sessionId,
    required bool showInLeaderboard,
    required bool isMulti,
    String? exerciseId,
    required String traceId,
    List<String> primaryMuscleGroupIds = const [],
    List<String> secondaryMuscleGroupIds = const [],
  });

  Future<int> fetchDayXp({
    required String userId,
    required DateTime date,
    bool forceRemote = false,
  });

  Future<Map<String, int>> fetchMuscleXp({
    required String gymId,
    required String userId,
    bool forceRemote = false,
  });

  Future<XpPagedResult<Map<String, Map<String, int>>>> fetchMuscleXpHistory({
    required String gymId,
    required String userId,
    int limit = kXpHistoryPageLimit,
    String? startAfter,
    bool forceRemote = false,
  });

  Future<XpPagedResult<Map<String, int>>> fetchTrainingDaysXp(
    String userId, {
    int limit = kXpTrainingDayPageLimit,
    String? startAfter,
    bool forceRemote = false,
  });

  Future<int> fetchDeviceXp({
    required String gymId,
    required String deviceId,
    required String userId,
    bool forceRemote = false,
  });

  Future<int> fetchStatsDailyXp({
    required String gymId,
    required String userId,
    bool forceRemote = false,
  });
}
