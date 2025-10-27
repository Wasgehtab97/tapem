import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tapem/core/storage/rest_stats_cache_store.dart';
import 'package:tapem/features/rest_stats/data/rest_stats_service.dart';
import 'package:tapem/features/rest_stats/domain/models/rest_stat_summary.dart';

class RestStatsProvider extends ChangeNotifier {
  RestStatsProvider({
    RestStatsService? service,
    RestStatsCacheStore? cacheStore,
    Duration? cacheTtl,
    DateTime Function()? nowProvider,
  })  : _service = service ?? RestStatsService(),
        _cacheStore = cacheStore ?? const RestStatsCacheStore(),
        _cacheTtl = cacheTtl ?? const Duration(hours: 6),
        _nowProvider = nowProvider ?? DateTime.now;

  final RestStatsService _service;
  final RestStatsCacheStore _cacheStore;
  final Duration _cacheTtl;
  final DateTime Function() _nowProvider;

  bool _isLoading = false;
  String? _error;
  List<RestStatSummary> _stats = const [];
  String? _activeGymId;
  String? _activeUserId;
  DateTime? _lastLoadedAt;
  Future<void>? _inFlight;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<RestStatSummary> get stats => List.unmodifiable(_stats);
  bool get hasData => _stats.isNotEmpty;

  double? get overallActualRestMs {
    final totalSets = totalSetCount;
    if (totalSets > 0) {
      final totalDuration = _stats.fold<double>(
        0,
        (acc, stat) => acc + stat.totalActualRestDurationMs,
      );
      if (totalDuration <= 0) {
        return null;
      }
      return totalDuration / totalSets;
    }
    final totalSamples = totalSampleCount;
    if (totalSamples == 0) return null;
    final totalSum =
        _stats.fold<double>(0, (acc, stat) => acc + stat.sumActualRestMs);
    return totalSum / totalSamples;
  }

  int get totalSampleCount =>
      _stats.fold<int>(0, (acc, stat) => acc + stat.sampleCount);

  int get totalSetCount =>
      _stats.fold<int>(0, (acc, stat) => acc + stat.sumSetCount);

  void _assignStats(List<RestStatSummary> stats, DateTime loadedAt) {
    stats.sort((a, b) {
      final aValue = a.effectiveAverageActualRestMs ?? 0;
      final bValue = b.effectiveAverageActualRestMs ?? 0;
      final valueComparison = bValue.compareTo(aValue);
      if (valueComparison != 0) {
        return valueComparison;
      }

      final aLast = a.lastSessionAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bLast = b.lastSessionAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final recencyComparison = bLast.compareTo(aLast);
      if (recencyComparison != 0) {
        return recencyComparison;
      }

      final aLabel = '${a.deviceName} ${a.exerciseName ?? ''}'.trim().toLowerCase();
      final bLabel = '${b.deviceName} ${b.exerciseName ?? ''}'.trim().toLowerCase();
      return aLabel.compareTo(bLabel);
    });
    _stats = List.unmodifiable(stats);
    _lastLoadedAt = loadedAt;
  }

  void _resetState() {
    _isLoading = false;
    _error = null;
    _stats = const [];
    _lastLoadedAt = null;
    notifyListeners();
  }

  Future<void> load({
    required String gymId,
    required String userId,
    bool forceRefresh = false,
  }) async {
    if (gymId.isEmpty || userId.isEmpty) {
      _activeGymId = gymId;
      _activeUserId = userId;
      _resetState();
      return;
    }

    final contextChanged =
        _activeGymId != gymId || _activeUserId != userId;
    if (contextChanged) {
      _activeGymId = gymId;
      _activeUserId = userId;
      _isLoading = false;
      _error = null;
      _stats = const [];
      _lastLoadedAt = null;
      notifyListeners();
    }

    if (!forceRefresh && !contextChanged && _stats.isNotEmpty) {
      final last = _lastLoadedAt;
      if (last != null) {
        final now = _nowProvider();
        if (now.difference(last) < _cacheTtl) {
          return;
        }
      }
    }

    if (_inFlight != null) {
      await _inFlight;
      return;
    }

    final completer = Completer<void>();
    _inFlight = completer.future;

    try {
      if (!forceRefresh) {
        final cached = await _cacheStore.read(gymId, userId);
        if (cached != null) {
          final now = _nowProvider();
          final expired = cached.isExpired(now, _cacheTtl);
          _assignStats(cached.stats, cached.cachedAt);
          _error = null;
          _isLoading = expired;
          notifyListeners();
          if (!expired) {
            completer.complete();
            _inFlight = null;
            return;
          }
        }
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      final fresh = await _service.fetchStats(gymId: gymId, userId: userId);
      final now = _nowProvider();
      _assignStats(fresh, now);
      _isLoading = false;
      _error = null;
      notifyListeners();
      await _cacheStore.write(
        gymId,
        userId,
        RestStatsCacheEntry(stats: fresh, cachedAt: now),
      );
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    } finally {
      completer.complete();
      _inFlight = null;
    }
  }

  Future<void> refresh() async {
    final gymId = _activeGymId;
    final userId = _activeUserId;
    if (gymId == null || userId == null) {
      return;
    }
    await load(gymId: gymId, userId: userId, forceRefresh: true);
  }
}
