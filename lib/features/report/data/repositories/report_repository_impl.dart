// lib/features/report/data/repositories/report_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/report/data/sources/firestore_report_source.dart';
import 'package:tapem/features/report/domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final FirestoreReportSource _source;
  ReportRepositoryImpl([FirestoreReportSource? source])
      : _source = source ?? FirestoreReportSource();

  @override
  Future<Map<String, int>> fetchUsageCountPerMachine(String gymId) async {
    final devices = await _source.fetchDevices(gymId);
    final Map<String, int> counts = {};

    for (final deviceDoc in devices) {
      final deviceId = deviceDoc.id;
      final logs = await _source.fetchLogsForDevice(gymId, deviceId);

      // Einzigartige sessionId sammeln
      final sessionIds = <String>{};
      for (final logDoc in logs) {
        final data = logDoc.data();
        final sid = data?['sessionId'] as String?;
        if (sid != null) sessionIds.add(sid);
      }

      // Anzahl der Sessions = Anzahl der eindeutigen sessionIds
      counts[deviceId] = sessionIds.length;
    }

    return counts;
  }

  @override
  Future<List<DateTime>> fetchAllLogTimestamps(String gymId) async {
    final devices = await _source.fetchDevices(gymId);
    final List<DateTime> allTimestamps = [];

    for (final deviceDoc in devices) {
      final deviceId = deviceDoc.id;
      final logs = await _source.fetchLogsForDevice(gymId, deviceId);
      for (final logDoc in logs) {
        final data = logDoc.data();
        final ts = data?['timestamp'];
        if (ts is Timestamp) {
          allTimestamps.add(ts.toDate());
        }
      }
    }

    return allTimestamps;
  }
}
