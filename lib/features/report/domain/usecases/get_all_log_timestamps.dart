// lib/features/report/domain/usecases/get_all_log_timestamps.dart
import 'package:tapem/features/report/domain/repositories/report_repository.dart';

class GetAllLogTimestamps {
  final ReportRepository _repo;
  GetAllLogTimestamps(this._repo);

  Future<List<DateTime>> execute(String gymId) {
    return _repo.fetchAllLogTimestamps(gymId);
  }
}
