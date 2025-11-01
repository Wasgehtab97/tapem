import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/leaderboard_entry.dart';
import '../../domain/services/leaderboard_service.dart';
import '../../domain/utils/leaderboard_time_utils.dart';

enum DeviceLeaderboardStatus { initial, loading, loaded, empty, error }

class DeviceLeaderboardTabState {
  final DeviceLeaderboardStatus status;
  final List<LeaderboardEntry> entries;
  final String? errorMessage;

  const DeviceLeaderboardTabState._({
    required this.status,
    this.entries = const [],
    this.errorMessage,
  });

  const DeviceLeaderboardTabState.initial()
      : this._(status: DeviceLeaderboardStatus.initial);

  const DeviceLeaderboardTabState.loading()
      : this._(status: DeviceLeaderboardStatus.loading);

  const DeviceLeaderboardTabState.empty()
      : this._(status: DeviceLeaderboardStatus.empty, entries: const []);

  const DeviceLeaderboardTabState.loaded(List<LeaderboardEntry> entries)
      : this._(status: DeviceLeaderboardStatus.loaded, entries: entries);

  DeviceLeaderboardTabState.error(String message)
      : this._(
          status: DeviceLeaderboardStatus.error,
          errorMessage: message,
        );
}

class DeviceLeaderboardNotifier extends ChangeNotifier {
  final LeaderboardService _service;
  final String gymId;
  final String machineId;
  final bool isMulti;

  LeaderboardPeriod _currentPeriod = LeaderboardPeriod.today;
  LeaderboardGenderFilter _genderFilter;
  LeaderboardScoreMode _scoreMode;

  final Map<LeaderboardPeriod, DeviceLeaderboardTabState> _tabs = {
    LeaderboardPeriod.today: const DeviceLeaderboardTabState.initial(),
    LeaderboardPeriod.week: const DeviceLeaderboardTabState.initial(),
    LeaderboardPeriod.month: const DeviceLeaderboardTabState.initial(),
  };

  DeviceLeaderboardNotifier({
    required LeaderboardService service,
    required this.gymId,
    required this.machineId,
    required this.isMulti,
    LeaderboardGenderFilter initialGenderFilter =
        LeaderboardGenderFilter.all,
    LeaderboardScoreMode initialScoreMode = LeaderboardScoreMode.absolute,
  })  : _service = service,
        _genderFilter = initialGenderFilter,
        _scoreMode = initialScoreMode;

  LeaderboardPeriod get currentPeriod => _currentPeriod;
  LeaderboardGenderFilter get genderFilter => _genderFilter;
  LeaderboardScoreMode get scoreMode => _scoreMode;

  DeviceLeaderboardTabState stateFor(LeaderboardPeriod period) =>
      _tabs[period] ?? const DeviceLeaderboardTabState.initial();

  Future<void> ensureLoaded([LeaderboardPeriod? period]) async {
    final target = period ?? _currentPeriod;
    final currentState = stateFor(target);
    if (isMulti) {
      return;
    }
    if (currentState.status == DeviceLeaderboardStatus.initial ||
        currentState.status == DeviceLeaderboardStatus.error) {
      await load(period: target, force: true);
    }
  }

  Future<void> load({
    LeaderboardPeriod? period,
    bool force = false,
  }) async {
    final target = period ?? _currentPeriod;
    if (isMulti) {
      return;
    }
    final currentState = stateFor(target);
    if (!force &&
        (currentState.status == DeviceLeaderboardStatus.loading ||
            currentState.status == DeviceLeaderboardStatus.loaded)) {
      return;
    }
    _tabs[target] = const DeviceLeaderboardTabState.loading();
    notifyListeners();
    try {
      final entries = await _service.loadLeaderboard(
        gymId: gymId,
        machineId: machineId,
        period: target,
        genderFilter: _genderFilter,
        mode: _scoreMode,
      );
      if (entries.isEmpty) {
        _tabs[target] = const DeviceLeaderboardTabState.empty();
      } else {
        _tabs[target] = DeviceLeaderboardTabState.loaded(entries);
      }
    } catch (e) {
      _tabs[target] = DeviceLeaderboardTabState.error(e.toString());
    }
    notifyListeners();
  }

  void setPeriod(LeaderboardPeriod period) {
    if (_currentPeriod == period) {
      return;
    }
    _currentPeriod = period;
    notifyListeners();
    unawaited(ensureLoaded(period));
  }

  void setGenderFilter(LeaderboardGenderFilter filter) {
    if (_genderFilter == filter) {
      return;
    }
    _genderFilter = filter;
    _resetStates();
    notifyListeners();
    unawaited(load(force: true));
  }

  void setScoreMode(LeaderboardScoreMode mode) {
    if (_scoreMode == mode) {
      return;
    }
    _scoreMode = mode;
    _resetStates();
    notifyListeners();
    unawaited(load(force: true));
  }

  void _resetStates() {
    for (final period in LeaderboardPeriod.values) {
      _tabs[period] = const DeviceLeaderboardTabState.initial();
    }
  }
}
