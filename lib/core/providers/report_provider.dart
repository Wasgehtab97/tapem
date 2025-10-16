// lib/core/providers/report_provider.dart

import 'package:flutter/material.dart';
import 'package:tapem/core/services/device_usage_summary_service.dart';
import 'package:tapem/core/services/training_summary_service.dart';
import 'package:tapem/features/report/domain/models/device_usage_range.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';

enum ReportState { initial, loading, loaded, error }

class ReportProvider extends ChangeNotifier {
  ReportProvider({
    DeviceUsageSummaryService? deviceSummaryService,
    TrainingSummaryService? trainingSummaryService,
  })  : _deviceSummaryService =
            deviceSummaryService ?? DeviceUsageSummaryService(),
        _trainingSummaryService =
            trainingSummaryService ?? TrainingSummaryService();

  final DeviceUsageSummaryService _deviceSummaryService;
  final TrainingSummaryService _trainingSummaryService;
  List<DeviceUsageSummaryEntry> _deviceEntries = const [];
  Map<String, int> _groupUsageCounts = const {};
  ReportState state = ReportState.initial;
  List<DeviceUsageStat> usageStats = const [];
  List<DateTime> heatmapDates = [];
  Map<String, int> get groupUsageCounts => Map.unmodifiable(_groupUsageCounts);
  String? errorMessage;
  DeviceUsageRange usageRange = DeviceUsageRange.last30Days;

  String? _currentGymId;
  String? _currentUserId;
  DateTime? _lastFetch;
  Future<void>? _activeLoad;
  static const Duration _cacheTtl = Duration(minutes: 5);

  Future<void> loadReport(
    String gymId, {
    bool forceRefresh = false,
    String? userId,
  }) async {
    if (gymId.isEmpty) {
      state = ReportState.initial;
      usageStats = const [];
      heatmapDates = [];
      errorMessage = null;
      _currentGymId = null;
      _lastFetch = null;
      _currentUserId = null;
      _groupUsageCounts = const {};
      notifyListeners();
      return;
    }
    _currentUserId = userId ?? _currentUserId;
    final now = DateTime.now();
    final withinCache =
        !forceRefresh &&
            _currentGymId == gymId &&
            _lastFetch != null &&
            now.difference(_lastFetch!) < _cacheTtl &&
            state == ReportState.loaded;
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

    final future = _loadData(
      gymId: gymId,
      userId: _currentUserId,
      forceRefresh: forceRefresh,
    ).whenComplete(() {
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
    _rebuildUsageStats();
    notifyListeners();
  }

  Future<void> refresh() {
    final gymId = _currentGymId;
    if (gymId == null || gymId.isEmpty) {
      return Future<void>.value();
    }
    return loadReport(
      gymId,
      forceRefresh: true,
      userId: _currentUserId,
    );
  }

  Future<void> _loadData({
    required String gymId,
    required bool forceRefresh,
    String? userId,
  }) async {
    try {
      final deviceState = await _deviceSummaryService.loadSummaries(
        gymId,
        forceRefresh: forceRefresh,
      );

      _deviceEntries = deviceState.entries;
      _rebuildUsageStats();
      heatmapDates = _collectHeatmapDates(_deviceEntries);

      if (userId != null && userId.isNotEmpty) {
        _groupUsageCounts = await _trainingSummaryService.fetchGroupUsageCounts(
          gymId: gymId,
          userId: userId,
          forceRefresh: forceRefresh,
        );
      } else {
        _groupUsageCounts = const {};
      }

      state = ReportState.loaded;
      _lastFetch = DateTime.now();
    } catch (e) {
      errorMessage = e.toString();
      state = ReportState.error;
    }
    notifyListeners();
  }

  void _rebuildUsageStats() {
    usageStats = _deviceEntries
        .map(
          (entry) => DeviceUsageStat(
            id: entry.deviceId,
            name: entry.name,
            description: entry.description,
            sessions: entry.countForRangeKey(usageRange.rangeKey),
            totalSessions: entry.totalSessions,
            lastActive: entry.lastActive,
          ),
        )
        .toList();
  }

  List<DateTime> _collectHeatmapDates(List<DeviceUsageSummaryEntry> entries) {
    final uniqueDays = <DateTime>{};
    for (final entry in entries) {
      for (final date in entry.recentDates) {
        uniqueDays.add(DateTime(date.year, date.month, date.day));
      }
    }
    final list = uniqueDays.toList()
      ..sort((a, b) => a.compareTo(b));
    return list;
  }
}
