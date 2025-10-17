import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';
import 'package:tapem/features/report/domain/repositories/report_repository.dart';
import 'package:tapem/features/report/domain/usecases/get_all_log_timestamps.dart';
import 'package:tapem/features/report/domain/usecases/get_device_usage_stats.dart';

class FakeReportRepository implements ReportRepository {
  int usageCalls = 0;
  int timeCalls = 0;

  DateTime? lastSince;

  @override
  Future<List<DeviceUsageStat>> fetchDeviceUsageStats(
    String gymId, {
    DateTime? since,
  }) async {
    usageCalls++;
    lastSince = since;
    return const [
      DeviceUsageStat(id: 'd1', name: 'Device', sessions: 1),
    ];
  }

  @override
  Future<List<DateTime>> fetchAllLogTimestamps(
    String gymId, {
    DateTime? since,
  }) async {
    timeCalls++;
    lastSince = since;
    return [DateTime(2024)];
  }
}

void main() {
  group('Report usecases', () {
    test('GetDeviceUsageStats delegates to repository', () async {
      final repo = FakeReportRepository();
      final usecase = GetDeviceUsageStats(repo);
      final now = DateTime(2024, 01, 15);
      final result = await usecase.execute('g1', since: now);
      expect(result.first.sessions, 1);
      expect(repo.usageCalls, 1);
      expect(repo.lastSince, now);
    });

    test('GetAllLogTimestamps delegates to repository', () async {
      final repo = FakeReportRepository();
      final usecase = GetAllLogTimestamps(repo);
      final rangeSince = DateTime(2024, 1, 1);
      final result = await usecase.execute('g1', since: rangeSince);
      expect(result.length, 1);
      expect(repo.timeCalls, 1);
      expect(repo.lastSince, rangeSince);
    });
  });
}
