// lib/features/report/data/repositories/report_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/report/data/sources/firestore_report_source.dart';
import 'package:tapem/features/report/domain/models/device_usage_range.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';
import 'package:tapem/features/report/domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final FirestoreReportSource _source;
  ReportRepositoryImpl([FirestoreReportSource? source])
    : _source = source ?? FirestoreReportSource();

  @override
  Future<List<DeviceUsageStat>> fetchDeviceUsageStats(
    String gymId, {
    required DeviceUsageRange range,
  }) async {
    final devices = await _source.fetchDevices(gymId);
    final now = DateTime.now();
    final since = range.resolveSince(now);
    final stats = await Future.wait(devices.map((deviceDoc) async {
      final deviceId = deviceDoc.id;
      final deviceData = deviceDoc.data();
      final deviceName = (deviceData?['name'] as String?)?.trim();
      final description = (deviceData?['description'] as String?)?.trim();

      final summarySnap = await _source.fetchDeviceUsageSummary(gymId, deviceId);
      final sessionsFromSummary = _extractSessionsFromSummary(summarySnap, range);
      if (sessionsFromSummary != null) {
        return DeviceUsageStat(
          id: deviceId,
          name: deviceName?.isNotEmpty == true ? deviceName! : deviceId,
          description: description ?? '',
          sessions: sessionsFromSummary,
        );
      }

      final logs = await _source.fetchLogsForDevice(
        gymId,
        deviceId,
        since: since,
      );

      final sessionIds = <String>{};
      for (final logDoc in logs) {
        final data = logDoc.data();
        final sid = data?['sessionId'] as String?;
        if (sid != null && sid.trim().isNotEmpty) {
          sessionIds.add(sid.trim());
        }
      }

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
    final summarySnap = await _source.fetchGymUsageSummary(gymId);
    final aggregated = _extractHeatmapDates(summarySnap);
    if (aggregated != null) {
      return aggregated;
    }

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

  int? _extractSessionsFromSummary(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    DeviceUsageRange range,
  ) {
    if (!snapshot.exists) {
      return null;
    }
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    final key = range.storageKey;
    final counts = data['sessionCounts'];
    if (counts is Map<String, dynamic>) {
      final raw = counts[key] ?? counts[key.toLowerCase()];
      if (raw is num) {
        return raw.toInt();
      }
      if (key != 'all') {
        final fallback = counts['all'] ?? counts['total'] ?? counts['overall'];
        if (fallback is num) {
          return fallback.toInt();
        }
      }
    }
    final direct = data['sessions'] ?? data['totalSessions'];
    if (direct is num) {
      return direct.toInt();
    }
    return null;
  }

  List<DateTime>? _extractHeatmapDates(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists) {
      return null;
    }
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    final rawList = data['heatmapDates'] ?? data['logDates'];
    if (rawList is! List) {
      return null;
    }
    final result = <DateTime>[];
    for (final entry in rawList) {
      DateTime? parsed;
      if (entry is Timestamp) {
        parsed = entry.toDate();
      } else if (entry is String) {
        parsed = DateTime.tryParse(entry);
        if (parsed == null && entry.length == 8) {
          final year = int.tryParse(entry.substring(0, 4));
          final month = int.tryParse(entry.substring(4, 6));
          final day = int.tryParse(entry.substring(6, 8));
          if (year != null && month != null && day != null) {
            parsed = DateTime(year, month, day);
          }
        }
      }
      if (parsed != null) {
        result.add(DateTime(parsed.year, parsed.month, parsed.day));
      }
    }
    return result.isEmpty ? null : result;
  }
}
