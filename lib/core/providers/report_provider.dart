// lib/core/providers/report_provider.dart

import 'package:flutter/material.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';
import 'package:tapem/features/report/domain/usecases/get_device_usage_stats.dart';
import 'package:tapem/features/report/domain/usecases/get_all_log_timestamps.dart';

enum ReportState { initial, loading, loaded, error }

enum DeviceUsageRange { last7Days, last30Days, last90Days, last365Days, all }

extension DeviceUsageRangeX on DeviceUsageRange {
  DateTime? resolveSince(DateTime now) {
    switch (this) {
      case DeviceUsageRange.last7Days:
        return now.subtract(const Duration(days: 7));
      case DeviceUsageRange.last30Days:
        return now.subtract(const Duration(days: 30));
      case DeviceUsageRange.last90Days:
        return now.subtract(const Duration(days: 90));
      case DeviceUsageRange.last365Days:
        return now.subtract(const Duration(days: 365));
      case DeviceUsageRange.all:
        return null;
    }
  }
}

class ReportProvider extends ChangeNotifier {
  final GetDeviceUsageStats _getUsage;
  final GetAllLogTimestamps _getTimestamps;

  ReportState state = ReportState.initial;
  List<DeviceUsageStat> usageStats = const [];
  List<DateTime> heatmapDates = [];
  String? errorMessage;
  DeviceUsageRange usageRange = DeviceUsageRange.last30Days;

  String? _currentGymId;

  ReportProvider({
    required GetDeviceUsageStats getUsageStats,
    required GetAllLogTimestamps getLogTimestamps,
  }) : _getUsage = getUsageStats,
       _getTimestamps = getLogTimestamps;

  Future<void> loadReport(String gymId) async {
    if (gymId.isEmpty) {
      state = ReportState.initial;
      usageStats = const [];
      heatmapDates = [];
      errorMessage = null;
      _currentGymId = null;
      notifyListeners();
      return;
    }
    _currentGymId = gymId;
    state = ReportState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final usageFuture = _fetchUsageStats(gymId);
      final timestampsFuture = _getTimestamps.execute(gymId);

      usageStats = await usageFuture;
      heatmapDates = await timestampsFuture;
      state = ReportState.loaded;
    } catch (e) {
      errorMessage = e.toString();
      state = ReportState.error;
    }
    notifyListeners();
  }

  Future<void> changeUsageRange(DeviceUsageRange range) async {
    if (usageRange == range) {
      return;
    }
    usageRange = range;
    if (_currentGymId == null || _currentGymId!.isEmpty) {
      notifyListeners();
      return;
    }
    state = ReportState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      usageStats = await _fetchUsageStats(_currentGymId!);
      state = ReportState.loaded;
    } catch (e) {
      errorMessage = e.toString();
      state = ReportState.error;
    }
    notifyListeners();
  }

  Future<List<DeviceUsageStat>> _fetchUsageStats(String gymId) {
    final now = DateTime.now();
    final since = usageRange.resolveSince(now);
    return _getUsage.execute(gymId, since: since);
  }
}
