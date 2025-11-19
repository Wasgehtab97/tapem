import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tapem/core/providers/gym_scoped_resettable.dart';
import 'package:tapem/core/providers/shared_preferences_provider.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';
import 'package:tapem/features/report/domain/repositories/report_repository.dart';
import 'package:tapem/features/report/domain/usecases/get_all_log_timestamps.dart';
import 'package:tapem/features/report/domain/usecases/get_device_usage_stats.dart';
import 'package:tapem/features/report/providers/report_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Report stats reload when gym context resets', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _FakeReportRepository();
    final usage = GetDeviceUsageStats(repo);
    final logs = GetAllLogTimestamps(repo);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        getDeviceUsageStatsProvider.overrideWithValue(usage),
        getAllLogTimestampsProvider.overrideWithValue(logs),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(reportProvider);

    await notifier.loadReport('gym-1');
    expect(repo.requestedGymIds, ['gym-1']);

    container.read(gymScopedStateControllerProvider).resetGymScopedState();

    await notifier.loadReport('gym-2');
    expect(repo.requestedGymIds, ['gym-1', 'gym-2']);
  });
}

class _FakeReportRepository implements ReportRepository {
  final List<String> requestedGymIds = [];

  @override
  Future<List<DateTime>> fetchAllLogTimestamps(
    String gymId, {
    DateTime? since,
  }) async {
    return <DateTime>[];
  }

  @override
  Future<List<DeviceUsageStat>> fetchDeviceUsageStats(
    String gymId, {
    DateTime? since,
  }) async {
    requestedGymIds.add(gymId);
    return [
      DeviceUsageStat(
        id: 'device-1',
        name: 'Device 1',
        description: '',
        sessions: 1,
      ),
    ];
  }
}
