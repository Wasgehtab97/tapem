// lib/core/providers/report_provider.dart

import 'package:flutter/material.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';
import 'package:tapem/features/report/domain/usecases/get_device_usage_stats.dart';
import 'package:tapem/features/report/domain/usecases/get_all_log_timestamps.dart';

enum ReportState { initial, loading, loaded, error }

class ReportProvider extends ChangeNotifier {
  final GetDeviceUsageStats _getUsage;
  final GetAllLogTimestamps _getTimestamps;

  ReportState state = ReportState.initial;
  List<DeviceUsageStat> usageStats = const [];
  List<DateTime> heatmapDates = [];
  String? errorMessage;

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
      notifyListeners();
      return;
    }
    state = ReportState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      usageStats = await _getUsage.execute(gymId);
      heatmapDates = await _getTimestamps.execute(gymId);
      state = ReportState.loaded;
    } catch (e) {
      errorMessage = e.toString();
      state = ReportState.error;
    }
    notifyListeners();
  }
}
