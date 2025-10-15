// lib/core/providers/report_provider.dart

import 'package:flutter/material.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';
import 'package:tapem/features/report/domain/models/device_usage_range.dart';
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
  DateTime? _lastFetch;
  Future<void>? _activeLoad;
  static const Duration _cacheTtl = Duration(minutes: 5);

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
      _lastFetch = null;
      notifyListeners();
      return;
    }
    final now = DateTime.now();
    final withinCache =
        !forceRefresh && _currentGymId == gymId && _lastFetch != null &&
        now.difference(_lastFetch!) < _cacheTtl && state == ReportState.loaded;
    if (withinCache) {
      return;
    }

    if (_activeLoad != null) {
      return _activeLoad!;
    }

    state = ReportState.loading;
    errorMessage = null;
    _currentGymId = gymId;
    notifyListeners();

    final future = _loadData(gymId, forceRefresh: forceRefresh)
        .whenComplete(() {
      _activeLoad = null;
    });
    _activeLoad = future;
    return future;
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

  Future<void> refresh() {
    final gymId = _currentGymId;
    if (gymId == null || gymId.isEmpty) {
      return Future<void>.value();
    }
    return loadReport(gymId, forceRefresh: true);
  }

  Future<void> _loadData(String gymId, {required bool forceRefresh}) async {
    try {
      final usageFuture = _getUsage.execute(
        gymId,
        range: usageRange,
        forceRefresh: forceRefresh,
      );
      final timestampsFuture = _getTimestamps.execute(
        gymId,
        forceRefresh: forceRefresh,
      );

      usageStats = await usageFuture;
      heatmapDates = await timestampsFuture;
      state = ReportState.loaded;
      _lastFetch = DateTime.now();
    } catch (e) {
      errorMessage = e.toString();
      state = ReportState.error;
    }
    notifyListeners();
  }
}
