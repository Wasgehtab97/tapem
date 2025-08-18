// lib/features/report/domain/usecases/get_device_usage_stats.dart
import 'package:tapem/features/report/domain/repositories/report_repository.dart';

class GetDeviceUsageStats {
  final ReportRepository _repo;
  GetDeviceUsageStats(this._repo);

  Future<Map<String, int>> execute(String gymId, String userId) {
    return _repo.fetchUsageCountPerMachine(gymId, userId);
  }
}
