// lib/features/report/domain/usecases/get_device_usage_stats.dart
import '../models/device_usage_range.dart';
import '../models/device_usage_stat.dart';
import '../repositories/report_repository.dart';

class GetDeviceUsageStats {
  final ReportRepository _repo;
  GetDeviceUsageStats(this._repo);

  Future<List<DeviceUsageStat>> execute(
    String gymId, {
    required DeviceUsageRange range,
  }) {
    return _repo.fetchDeviceUsageStats(
      gymId,
      range: range,
    );
  }
}
