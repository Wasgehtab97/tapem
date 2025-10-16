// lib/features/report/data/repositories/report_repository_impl.dart

import 'package:tapem/core/services/device_usage_summary_service.dart';
import 'package:tapem/features/report/domain/models/device_usage_range.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';
import 'package:tapem/features/report/domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl({
    DeviceUsageSummaryService? summaryService,
  }) : _summaryService = summaryService ?? DeviceUsageSummaryService();

  final DeviceUsageSummaryService _summaryService;

  @override
  Future<List<DeviceUsageStat>> fetchDeviceUsageStats(
    String gymId,
    DeviceUsageRange range, {
    bool forceRefresh = false,
  }) async {
    final state = await _summaryService.loadSummaries(
      gymId,
      forceRefresh: forceRefresh,
    );

    return state.entries
        .map(
          (entry) => DeviceUsageStat(
            id: entry.deviceId,
            name: entry.name,
            description: entry.description,
            sessions: entry.countForRangeKey(range.rangeKey),
            totalSessions: entry.totalSessions,
            lastActive: entry.lastActive,
          ),
        )
        .toList();
  }

  @override
  Future<List<DateTime>> fetchRecentLogTimestamps(
    String gymId, {
    bool forceRefresh = false,
  }) {
    return _summaryService.fetchRecentActivityDates(
      gymId,
      forceRefresh: forceRefresh,
    );
  }
}
