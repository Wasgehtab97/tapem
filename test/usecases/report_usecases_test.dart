import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/report/domain/models/device_usage_range.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';
import 'package:tapem/features/report/domain/repositories/report_repository.dart';
import 'package:tapem/features/report/domain/usecases/get_all_log_timestamps.dart';
import 'package:tapem/features/report/domain/usecases/get_device_usage_stats.dart';

class FakeReportRepository implements ReportRepository {
  int usageCalls = 0;
  int timeCalls = 0;

  DeviceUsageRange? lastRange;

  @override
  Future<List<DeviceUsageStat>> fetchDeviceUsageStats(
    String gymId, {
    required DeviceUsageRange range,
  }) async {
    usageCalls++;
    lastRange = range;
    return const [
      DeviceUsageStat(id: 'd1', name: 'Device', sessions: 1),
    ];
  }

  @override
  Future<List<DateTime>> fetchAllLogTimestamps(String gymId) async {
    timeCalls++;
    return [DateTime(2024)];
  }
}

void main() {
  group('Report usecases', () {
    test('GetDeviceUsageStats delegates to repository', () async {
      final repo = FakeReportRepository();
      final usecase = GetDeviceUsageStats(repo);
      final result = await usecase.execute(
        'g1',
        range: DeviceUsageRange.last30Days,
      );
      expect(result.first.sessions, 1);
      expect(repo.usageCalls, 1);
      expect(repo.lastRange, DeviceUsageRange.last30Days);
    });

    test('GetAllLogTimestamps delegates to repository', () async {
      final repo = FakeReportRepository();
      final usecase = GetAllLogTimestamps(repo);
      final result = await usecase.execute('g1');
      expect(result.length, 1);
      expect(repo.timeCalls, 1);
    });
  });
}
