import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:tapem/features/rank/data/repositories/rank_repository_impl.dart';
import 'package:tapem/features/rank/data/sources/firestore_rank_source.dart';
import 'package:tapem/features/rank/domain/rank_repository.dart';

class RankProvider extends ChangeNotifier {
  RankProvider({RankRepository? repository})
      : _repository = repository ?? RankRepositoryImpl(FirestoreRankSource());

  final RankRepository _repository;

  final Duration _cacheTtl = const Duration(minutes: 2);
  final Duration _pollInterval = const Duration(minutes: 2);

  List<Map<String, dynamic>> _deviceEntries = [];
  String? _gymId;
  String? _deviceId;
  DateTime? _lastFetch;
  bool _loading = false;
  Timer? _pollTimer;

  List<Map<String, dynamic>> get deviceEntries => List.unmodifiable(_deviceEntries);

  void watchDevice(String gymId, String deviceId) {
    _gymId = gymId.isEmpty ? null : gymId;
    _deviceId = deviceId.isEmpty ? null : deviceId;
    _ensurePolling();
    if (_gymId == null || _deviceId == null) {
      _deviceEntries = [];
      notifyListeners();
      return;
    }
    unawaited(_loadLeaderboard(force: true));
  }

  Future<void> refresh() => _loadLeaderboard(force: true);

  Future<void> _loadLeaderboard({bool force = false}) async {
    if (_loading || _gymId == null || _deviceId == null) {
      return;
    }
    if (!force && _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTtl) {
      return;
    }
    _loading = true;
    try {
      final data = await _repository.fetchLeaderboard(_gymId!, _deviceId!);
      _deviceEntries = data;
      _lastFetch = DateTime.now();
      notifyListeners();
    } finally {
      _loading = false;
    }
  }

  void _ensurePolling() {
    if (_gymId == null || _deviceId == null) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    _pollTimer ??= Timer.periodic(_pollInterval, (_) {
      unawaited(_loadLeaderboard());
    });
  }

  Future<void> addXp(
    String gymId,
    String userId,
    String deviceId,
    String sessionId,
    bool showInLeaderboard,
  ) {
    return _repository.addXp(
      gymId,
      userId,
      deviceId,
      sessionId,
      showInLeaderboard,
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
