import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tapem/core/database/database_service.dart';
import 'package:tapem/core/sync/sync_service.dart';

import 'package:tapem/bootstrap/bootstrap.dart';
import 'package:tapem/bootstrap/providers.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';
import 'package:tapem/features/report/domain/repositories/report_repository.dart';
import 'package:tapem/features/report/domain/usecases/get_all_log_timestamps.dart';
import 'package:tapem/features/report/domain/usecases/get_device_usage_stats.dart';

class _FakeReportRepository implements ReportRepository {
  @override
  Future<List<DateTime>> fetchAllLogTimestamps(String gymId, {DateTime? since}) async {
    return const [];
  }

  @override
  Future<List<DeviceUsageStat>> fetchDeviceUsageStats(String gymId,
      {DateTime? since}) async {
    return const [];
  }
}

class _MockDatabaseService extends Mock implements DatabaseService {}
class _MockSyncService extends Mock implements SyncService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bootstrap overrides inject shared dependencies', () async {
    SharedPreferences.setMockInitialValues(const {});
    final sharedPrefs = await SharedPreferences.getInstance();
    final repo = _FakeReportRepository();
    final usage = GetDeviceUsageStats(repo);
    final logs = GetAllLogTimestamps(repo);

    final databaseService = _MockDatabaseService();
    final syncService = _MockSyncService();

    final result = BootstrapResult(
      sharedPreferences: sharedPrefs,
      getUsageStats: usage,
      getLogTimestamps: logs,
      databaseService: databaseService,
      syncService: syncService,
    );

    final container = ProviderContainer(overrides: result.toOverrides());

    expect(container.read(sharedPreferencesProvider), same(sharedPrefs));
    expect(container.read(getDeviceUsageStatsProvider), same(usage));
    expect(container.read(getAllLogTimestampsProvider), same(logs));
    expect(container.read(databaseServiceProvider), same(databaseService));
    expect(container.read(syncServiceProvider), same(syncService));
  });
}
