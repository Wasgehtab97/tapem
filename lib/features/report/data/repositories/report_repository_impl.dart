// lib/features/report/data/repositories/report_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/core/observability/owner_query_budget_service.dart';
import 'package:tapem/features/report/data/sources/firestore_report_source.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';
import 'package:tapem/features/report/domain/models/report_daily_aggregate.dart';
import 'package:tapem/features/report/domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  static const int _maxHeatmapPoints = 15000;
  static const OwnerQueryBudget _usageStatsBudget = OwnerQueryBudget(
    maxQueries: 120,
    maxDocsRead: 20000,
  );
  static const OwnerQueryBudget _timestampsBudget = OwnerQueryBudget(
    maxQueries: 120,
    maxDocsRead: 25000,
  );

  final FirestoreReportSource _source;
  final OwnerQueryBudgetService _queryBudgetService;
  ReportRepositoryImpl([
    FirestoreReportSource? source,
    OwnerQueryBudgetService? queryBudgetService,
  ]) : _source = source ?? FirestoreReportSource(),
       _queryBudgetService =
           queryBudgetService ?? OwnerQueryBudgetService.instance;

  @override
  Future<List<DeviceUsageStat>> fetchDeviceUsageStats(
    String gymId, {
    DateTime? since,
  }) async {
    return _queryBudgetService.track<List<DeviceUsageStat>>(
      flow: 'owner.report.usage_stats',
      budget: _usageStatsBudget,
      command: (counter) async {
        final devices = await _source.fetchDevices(gymId);
        counter.recordQueryResult(docsRead: devices.length);
        final aggregates = await _source.fetchDailyAggregates(
          gymId,
          since: since,
        );
        counter.recordQueryResult(docsRead: aggregates.length);
        if (aggregates.isNotEmpty) {
          final sessionCounts = _sumDeviceSessionCounts(aggregates);
          return devices
              .map((deviceDoc) {
                final deviceId = deviceDoc.id;
                final deviceData = deviceDoc.data();
                final deviceName = (deviceData?['name'] as String?)?.trim();
                final description = (deviceData?['description'] as String?)
                    ?.trim();
                return DeviceUsageStat(
                  id: deviceId,
                  name: deviceName?.isNotEmpty == true ? deviceName! : deviceId,
                  description: description ?? '',
                  sessions: sessionCounts[deviceId] ?? 0,
                );
              })
              .toList(growable: false);
        }

        return _fetchLegacyStats(
          gymId,
          devices: devices,
          since: since,
          counter: counter,
        );
      },
    );
  }

  @override
  Future<List<DateTime>> fetchAllLogTimestamps(
    String gymId, {
    DateTime? since,
  }) async {
    return _queryBudgetService.track<List<DateTime>>(
      flow: 'owner.report.heatmap_timestamps',
      budget: _timestampsBudget,
      command: (counter) async {
        final aggregates = await _source.fetchDailyAggregates(
          gymId,
          since: since,
        );
        counter.recordQueryResult(docsRead: aggregates.length);
        if (aggregates.isNotEmpty) {
          return _expandHeatmapTimestamps(
            aggregates,
            maxPoints: _maxHeatmapPoints,
          );
        }
        final devices = await _source.fetchDevices(gymId);
        counter.recordQueryResult(docsRead: devices.length);
        return _fetchLegacyTimestamps(
          gymId,
          devices: devices,
          since: since,
          counter: counter,
        );
      },
    );
  }

  Map<String, int> _sumDeviceSessionCounts(List<ReportDailyAggregate> days) {
    final totals = <String, int>{};
    for (final day in days) {
      day.deviceSessionCounts.forEach((deviceId, sessions) {
        if (sessions <= 0) {
          return;
        }
        totals.update(
          deviceId,
          (value) => value + sessions,
          ifAbsent: () => sessions,
        );
      });
    }
    return totals;
  }

  List<DateTime> _expandHeatmapTimestamps(
    List<ReportDailyAggregate> days, {
    required int maxPoints,
  }) {
    if (maxPoints <= 0) {
      return const <DateTime>[];
    }
    final sorted = List<ReportDailyAggregate>.from(days)
      ..sort((a, b) => a.dayUtc.compareTo(b.dayUtc));

    final timestamps = <DateTime>[];
    for (final day in sorted) {
      final sortedBuckets = day.hourBuckets.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final bucket in sortedBuckets) {
        final count = bucket.value;
        if (count <= 0) {
          continue;
        }
        final remaining = maxPoints - timestamps.length;
        if (remaining <= 0) {
          return timestamps;
        }
        final sampleCount = count < remaining ? count : remaining;
        final ts = DateTime.utc(
          day.dayUtc.year,
          day.dayUtc.month,
          day.dayUtc.day,
          bucket.key,
        );
        for (var i = 0; i < sampleCount; i++) {
          timestamps.add(ts);
        }
      }
    }
    return timestamps;
  }

  Future<List<DeviceUsageStat>> _fetchLegacyStats(
    String gymId, {
    required List<DocumentSnapshot<Map<String, dynamic>>> devices,
    DateTime? since,
    required OwnerQueryCounter counter,
  }) async {
    final stats = await Future.wait(
      devices.map((deviceDoc) async {
        final deviceId = deviceDoc.id;
        final deviceData = deviceDoc.data();
        final deviceName = (deviceData?['name'] as String?)?.trim();
        final description = (deviceData?['description'] as String?)?.trim();
        final logs = await _source.fetchLogsForDevice(
          gymId,
          deviceId,
          since: since,
        );
        counter.recordQueryResult(docsRead: logs.length);
        final sessionIds = <String>{};
        for (final logDoc in logs) {
          final data = logDoc.data();
          final sid = data?['sessionId'] as String?;
          if (sid != null && sid.isNotEmpty) {
            sessionIds.add(sid);
          }
        }

        return DeviceUsageStat(
          id: deviceId,
          name: deviceName?.isNotEmpty == true ? deviceName! : deviceId,
          description: description ?? '',
          sessions: sessionIds.length,
        );
      }),
    );
    return stats;
  }

  Future<List<DateTime>> _fetchLegacyTimestamps(
    String gymId, {
    required List<DocumentSnapshot<Map<String, dynamic>>> devices,
    DateTime? since,
    required OwnerQueryCounter counter,
  }) async {
    final allTimestamps = await Future.wait(
      devices.map((deviceDoc) async {
        final deviceId = deviceDoc.id;
        final logs = await _source.fetchLogsForDevice(
          gymId,
          deviceId,
          since: since,
        );
        counter.recordQueryResult(docsRead: logs.length);
        final timestamps = <DateTime>[];
        for (final logDoc in logs) {
          final data = logDoc.data();
          final ts = data?['timestamp'];
          if (ts is Timestamp) {
            timestamps.add(ts.toDate());
          }
        }
        return timestamps;
      }),
    );

    return allTimestamps.expand((timestamps) => timestamps).toList();
  }
}
