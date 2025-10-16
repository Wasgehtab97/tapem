// lib/features/report/domain/usecases/get_all_log_timestamps.dart
import 'package:tapem/features/report/domain/repositories/report_repository.dart';

class GetAllLogTimestamps {
  final ReportRepository _repo;
  GetAllLogTimestamps(this._repo);

  Future<List<DateTime>> execute(
    String gymId, {
    bool forceRefresh = false,
  }) {
    return _repo.fetchRecentLogTimestamps(
      gymId,
      forceRefresh: forceRefresh,
    );
  }
}
