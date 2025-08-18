import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/report/domain/usecases/get_device_usage_stats.dart';
import 'package:tapem/features/report/domain/usecases/get_all_log_timestamps.dart';
import 'package:tapem/features/report/domain/repositories/report_repository.dart';

class FakeReportRepository implements ReportRepository {
  int usageCalls = 0;
  int timeCalls = 0;

  @override
  Future<Map<String, int>> fetchUsageCountPerMachine(String gymId, String userId) async {
    usageCalls++;
    return {'d1': 1};
  }

  @override
  Future<List<DateTime>> fetchAllLogTimestamps(String gymId, String userId) async {
    timeCalls++;
    return [DateTime(2024)];
  }
}

void main() {
  group('Report usecases', () {
    test('GetDeviceUsageStats delegates to repository', () async {
      final repo = FakeReportRepository();
      final usecase = GetDeviceUsageStats(repo);
      final result = await usecase.execute("g1", "u1");
      expect(result, {'d1': 1});
      expect(repo.usageCalls, 1);
    });

    test('GetAllLogTimestamps delegates to repository', () async {
      final repo = FakeReportRepository();
      final usecase = GetAllLogTimestamps(repo);
      final result = await usecase.execute("g1", "u1");
      expect(result.length, 1);
      expect(repo.timeCalls, 1);
    });
  });
}
