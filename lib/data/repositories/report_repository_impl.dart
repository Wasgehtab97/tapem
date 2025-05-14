import 'package:tapem/domain/models/device_info.dart';
import 'package:tapem/domain/models/report_entry.dart';
import 'package:tapem/domain/repositories/report_repository.dart';
import 'package:tapem/data/sources/report/firestore_report_source.dart';


/// Firestore-Implementierung von [ReportRepository].
class ReportRepositoryImpl implements ReportRepository {
  final FirestoreReportSource _source;
  ReportRepositoryImpl({FirestoreReportSource? source})
      : _source = source ?? FirestoreReportSource();

  @override
  Future<List<DeviceInfo>> fetchDevices(String gymId) {
    return _source.fetchDevices(gymId);
  }

  @override
  Future<Map<String, String>> fetchFeedbackStatus(String gymId) {
    return _source.fetchFeedbackStatus(gymId);
  }

  @override
  Future<List<ReportEntry>> fetchReportData({
    required String gymId,
    String? deviceId,
    DateTime? start,
    DateTime? end,
  }) {
    return _source.fetchReportData(
      gymId: gymId,
      deviceId: deviceId,
      start: start,
      end: end,
    );
  }
}
