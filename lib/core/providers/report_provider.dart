// lib/core/providers/report_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/providers/gym_scoped_resettable.dart';
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

class ReportProvider extends ChangeNotifier with GymScopedResettableChangeNotifier {
  final GetDeviceUsageStats _getUsage;
  final GetAllLogTimestamps _getTimestamps;
  final SharedPreferences? _preferences;

  ReportState state = ReportState.initial;
  List<DeviceUsageStat> usageStats = const [];
  List<DateTime> heatmapDates = [];
  String? errorMessage;
  DeviceUsageRange usageRange = DeviceUsageRange.last30Days;

  String? _currentGymId;

  static const _usageRangePrefsKey = 'report_usage_range';

  ReportProvider({
    required GetDeviceUsageStats getUsageStats,
    required GetAllLogTimestamps getLogTimestamps,
    SharedPreferences? preferences,
  })  : _getUsage = getUsageStats,
        _getTimestamps = getLogTimestamps,
        _preferences = preferences {
    _restoreUsageRange();
  }

  void _restoreUsageRange() {
    final storedIndex = _preferences?.getInt(_usageRangePrefsKey);
    if (storedIndex == null) {
      return;
    }
    if (storedIndex < 0 || storedIndex >= DeviceUsageRange.values.length) {
      return;
    }
    usageRange = DeviceUsageRange.values[storedIndex];
  }

  String? get currentGymId => _currentGymId;

  bool shouldLoadReport(String gymId) {
    if (gymId.isEmpty) {
      return false;
    }
    if (_currentGymId != gymId) {
      return true;
    }
    return state == ReportState.initial || state == ReportState.error;
  }

  Future<void> loadReport(String gymId, {bool force = false}) async {
    if (gymId.isEmpty) {
      state = ReportState.initial;
      usageStats = const [];
      heatmapDates = [];
      errorMessage = null;
      _currentGymId = null;
      notifyListeners();
      return;
    }
    if (!force &&
        _currentGymId == gymId &&
        (state == ReportState.loaded || state == ReportState.loading)) {
      return;
    }

    final isNewGym = _currentGymId != gymId;
    _currentGymId = gymId;
    state = ReportState.loading;
    errorMessage = null;
    if (isNewGym) {
      heatmapDates = [];
    }
    notifyListeners();
    try {
      usageStats = await _fetchUsageStats(gymId);
      state = ReportState.loaded;
    } catch (e) {
      errorMessage = e.toString();
      state = ReportState.error;
    }
    notifyListeners();
  }

  Future<void> loadHeatmapDates({bool force = false}) async {
    final gymId = _currentGymId;
    if (gymId == null || gymId.isEmpty) {
      return;
    }
    if (!force && heatmapDates.isNotEmpty) {
      return;
    }
    try {
      final now = DateTime.now();
      final since = usageRange.resolveSince(now);
      heatmapDates = await _getTimestamps.execute(
        gymId,
        since: since,
      );
      notifyListeners();
    } catch (_) {
      // Heatmap-Daten sind optional. Fehler werden stillschweigend ignoriert,
      // um die restlichen Report-Daten nicht zu blockieren.
    }
  }

  Future<void> changeUsageRange(DeviceUsageRange range) async {
    if (usageRange == range) {
      return;
    }
    usageRange = range;
    await _preferences?.setInt(_usageRangePrefsKey, range.index);
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

  @override
  void resetGymScopedState() {
    state = ReportState.initial;
    usageStats = const [];
    heatmapDates = [];
    errorMessage = null;
    _currentGymId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeGymScopedRegistration();
    super.dispose();
  }
}
