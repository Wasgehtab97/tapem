// lib/core/providers/report_provider.dart

import 'package:flutter/material.dart';
import 'package:tapem/core/services/training_summary_service.dart';
import 'package:tapem/features/report/data/repositories/report_repository_impl.dart';
import 'package:tapem/features/report/domain/models/device_usage_range.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';
import 'package:tapem/features/report/domain/repositories/report_repository.dart';
import 'package:tapem/features/report/domain/usecases/get_all_log_timestamps.dart';
import 'package:tapem/features/report/domain/usecases/get_device_usage_stats.dart';

enum ReportState { initial, loading, loaded, error }

class ReportProvider extends ChangeNotifier {
  factory ReportProvider({
    GetDeviceUsageStats? getUsageStats,
    GetAllLogTimestamps? getLogTimestamps,
    TrainingSummaryService? trainingSummaryService,
    ReportRepository? reportRepository,
  }) {
    final repo = reportRepository ?? ReportRepositoryImpl();
    return ReportProvider._(
      getUsageStats ?? GetDeviceUsageStats(repo),
      getLogTimestamps ?? GetAllLogTimestamps(repo),
      trainingSummaryService ?? TrainingSummaryService(),
    );
  }

  ReportProvider._(
    this._getUsageStats,
    this._getLogTimestamps,
    this._trainingSummaryService,
  );

  final GetDeviceUsageStats _getUsageStats;
  final GetAllLogTimestamps _getLogTimestamps;
  final TrainingSummaryService _trainingSummaryService;
  final Map<DeviceUsageRange, _CachedUsageStats> _statsCache = {};
  _CachedHeatmap? _heatmapCache;
  Map<String, int> _groupUsageCounts = const {};
  ReportState state = ReportState.initial;
  List<DeviceUsageStat> usageStats = const [];
  List<DateTime> heatmapDates = const [];
  Map<String, int> get groupUsageCounts => Map.unmodifiable(_groupUsageCounts);
  String? errorMessage;
  DeviceUsageRange usageRange = DeviceUsageRange.last30Days;

  String? _currentGymId;
  String? _currentUserId;
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
      heatmapDates = const [];
      errorMessage = null;
      _currentGymId = null;
      _currentUserId = null;
      _groupUsageCounts = const {};
      _invalidateCache();
      notifyListeners();
      return;
    }
    final gymChanged = _currentGymId != null && _currentGymId != gymId;
    final previousUserId = _currentUserId;
    final userChanged = userId != null && userId != previousUserId;

    if (gymChanged || userChanged) {
      _invalidateCache();
    }

    _currentUserId = userId ?? _currentUserId;
    final now = DateTime.now();
    final cachedStats = _statsCache[usageRange];
    final cachedHeatmap = _heatmapCache;
    final shouldBypassCache = forceRefresh || gymChanged || userChanged;
    final hasValidCache =
        !shouldBypassCache &&
            cachedStats != null &&
            cachedHeatmap != null &&
            now.difference(cachedStats.fetchedAt) < _cacheTtl &&
            now.difference(cachedHeatmap.fetchedAt) < _cacheTtl &&
            state == ReportState.loaded;
    if (hasValidCache) {
      _currentGymId = gymId;
      return;
    }

    if (_activeLoad != null) {
      return _activeLoad!;
    }

    state = ReportState.loading;
    errorMessage = null;
    if (shouldBypassCache) {
      _invalidateCache();
    }
    _currentGymId = gymId;
    notifyListeners();

    final future = _loadData(
      gymId: gymId,
      userId: _currentUserId,
      forceRefresh: shouldBypassCache,
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
    final gymId = _currentGymId;
    if (gymId == null || gymId.isEmpty) {
      notifyListeners();
      return;
    }

    try {
      final stats = await _fetchUsageStats(
        gymId: gymId,
        range: range,
        forceRefresh: false,
      );
      usageStats = stats;
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
      final stats = await _fetchUsageStats(
        gymId: gymId,
        range: usageRange,
        forceRefresh: forceRefresh,
      );
      usageStats = stats;

      heatmapDates = await _fetchHeatmapDates(
        gymId: gymId,
        forceRefresh: forceRefresh,
      );

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
    } catch (e) {
      errorMessage = e.toString();
      state = ReportState.error;
    }
    notifyListeners();
  }

  Future<List<DeviceUsageStat>> _fetchUsageStats({
    required String gymId,
    required DeviceUsageRange range,
    required bool forceRefresh,
  }) async {
    final cached = _statsCache[range];
    final now = DateTime.now();
    final cacheValid =
        !forceRefresh && cached != null && now.difference(cached.fetchedAt) < _cacheTtl;
    if (cacheValid) {
      return cached.stats;
    }

    final stats = await _getUsageStats.execute(
      gymId,
      range: range,
      forceRefresh: forceRefresh,
    );
    final safeStats = List<DeviceUsageStat>.unmodifiable(stats);
    _statsCache[range] = _CachedUsageStats(
      stats: safeStats,
      fetchedAt: now,
    );
    return safeStats;
  }

  Future<List<DateTime>> _fetchHeatmapDates({
    required String gymId,
    required bool forceRefresh,
  }) async {
    final cached = _heatmapCache;
    final now = DateTime.now();
    final cacheValid =
        !forceRefresh && cached != null && now.difference(cached.fetchedAt) < _cacheTtl;
    if (cacheValid) {
      return cached.dates;
    }

    final timestamps = await _getLogTimestamps.execute(
      gymId,
      forceRefresh: forceRefresh,
    );
    final dates = _collectHeatmapDates(timestamps);
    final safeDates = List<DateTime>.unmodifiable(dates);
    _heatmapCache = _CachedHeatmap(
      dates: safeDates,
      fetchedAt: now,
    );
    return safeDates;
  }

  void _invalidateCache() {
    _statsCache.clear();
    _heatmapCache = null;
  }

  List<DateTime> _collectHeatmapDates(Iterable<DateTime> timestamps) {
    final uniqueDays = <DateTime>{};
    for (final date in timestamps) {
      uniqueDays.add(DateTime(date.year, date.month, date.day));
    }
    final list = uniqueDays.toList()
      ..sort((a, b) => a.compareTo(b));
    return list;
  }
}

class _CachedUsageStats {
  const _CachedUsageStats({
    required this.stats,
    required this.fetchedAt,
  });

  final List<DeviceUsageStat> stats;
  final DateTime fetchedAt;
}

class _CachedHeatmap {
  const _CachedHeatmap({
    required this.dates,
    required this.fetchedAt,
  });

  final List<DateTime> dates;
  final DateTime fetchedAt;
}
