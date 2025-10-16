// lib/core/providers/report_provider.dart

import 'package:flutter/material.dart';
import 'package:tapem/features/report/domain/models/device_usage_range.dart';
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
  DeviceUsageRange usageRange = DeviceUsageRange.last30Days;

  String? _currentGymId;
  String? _pendingGymId;
  Future<void>? _inFlightLoad;

  ReportProvider({
    required GetDeviceUsageStats getUsageStats,
    required GetAllLogTimestamps getLogTimestamps,
  }) : _getUsage = getUsageStats,
       _getTimestamps = getLogTimestamps;

  Future<void> loadReport(String gymId, {bool forceRefresh = false}) async {
    if (gymId.isEmpty) {
      state = ReportState.initial;
      usageStats = const [];
      heatmapDates = [];
      errorMessage = null;
      _currentGymId = null;
      notifyListeners();
      return;
    }
    if (!forceRefresh &&
        _currentGymId == gymId &&
        state == ReportState.loaded &&
        errorMessage == null) {
      return;
    }
    if (_inFlightLoad != null && _pendingGymId == gymId) {
      await _inFlightLoad;
      return;
    }
    _currentGymId = gymId;
    state = ReportState.loading;
    errorMessage = null;
    notifyListeners();
    final future = _loadReportInternal(gymId);
    _pendingGymId = gymId;
    _inFlightLoad = future.whenComplete(() {
      _pendingGymId = null;
      _inFlightLoad = null;
    });
    await _inFlightLoad;
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
      usageStats = await _getUsage.execute(
        _currentGymId!,
        range: usageRange,
      );
      state = ReportState.loaded;
    } catch (e) {
      errorMessage = e.toString();
      state = ReportState.error;
    }
    notifyListeners();
  }

  Future<void> _loadReportInternal(String gymId) async {
    try {
      final usageFuture = _getUsage.execute(
        gymId,
        range: usageRange,
      );
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
}
