// lib/features/report/data/repositories/report_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/report/data/sources/firestore_report_source.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';
import 'package:tapem/features/report/domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final FirestoreReportSource _source;
  ReportRepositoryImpl([FirestoreReportSource? source])
    : _source = source ?? FirestoreReportSource();

  @override
  Future<List<DeviceUsageStat>> fetchDeviceUsageStats(
    String gymId, {
    DateTime? since,
  }) async {
    final devices = await _source.fetchDevices(gymId);
    final stats = await Future.wait(devices.map((deviceDoc) async {
      final deviceId = deviceDoc.id;
      final deviceData = deviceDoc.data();
      final deviceName = (deviceData?['name'] as String?)?.trim();
      final description = (deviceData?['description'] as String?)?.trim();
      final logs = await _source.fetchLogsForDevice(
        gymId,
        deviceId,
        since: since,
      );

      // Einzigartige sessionId sammeln
      final sessionIds = <String>{};
      for (final logDoc in logs) {
        final data = logDoc.data();
        final sid = data?['sessionId'] as String?;
        if (sid != null) sessionIds.add(sid);
      }

      // Anzahl der Sessions = Anzahl der eindeutigen sessionIds
      return DeviceUsageStat(
        id: deviceId,
        name: deviceName?.isNotEmpty == true ? deviceName! : deviceId,
        description: description ?? '',
        sessions: sessionIds.length,
      );
    }));

    return stats;
  }

  @override
  Future<List<DateTime>> fetchAllLogTimestamps(String gymId) async {
    final devices = await _source.fetchDevices(gymId);
    final allTimestamps = await Future.wait(devices.map((deviceDoc) async {
      final deviceId = deviceDoc.id;
      final logs = await _source.fetchLogsForDevice(gymId, deviceId);
      final timestamps = <DateTime>[];
      for (final logDoc in logs) {
        final data = logDoc.data();
        final ts = data?['timestamp'];
        if (ts is Timestamp) {
          timestamps.add(ts.toDate());
        }
      }
      return timestamps;
    }));

    return allTimestamps.expand((timestamps) => timestamps).toList();
  }
}
