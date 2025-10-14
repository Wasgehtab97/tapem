import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:tapem/features/challenges/data/repositories/challenge_repository_impl.dart';
import 'package:tapem/features/challenges/data/sources/firestore_challenge_source.dart';
import 'package:tapem/features/challenges/domain/models/badge.dart';
import 'package:tapem/features/challenges/domain/models/challenge.dart';
import 'package:tapem/features/challenges/domain/models/completed_challenge.dart';
import 'package:tapem/features/challenges/domain/repositories/challenge_repository.dart';

class ChallengeProvider extends ChangeNotifier {
  ChallengeProvider({ChallengeRepository? repo})
      : _repo = repo ?? ChallengeRepositoryImpl(FirestoreChallengeSource());

  final ChallengeRepository _repo;

  final Duration _cacheTtl = const Duration(minutes: 5);
  final Duration _pollInterval = const Duration(minutes: 5);

  final List<Challenge> _rawChallenges = [];
  List<Challenge> _visibleChallenges = [];
  List<CompletedChallenge> _completed = [];
  List<Badge> _badges = [];

  String? _gymId;
  String? _userId;
  String? _badgeUserId;

  DateTime? _lastChallengesFetch;
  DateTime? _lastCompletedFetch;
  DateTime? _lastBadgesFetch;

  bool _loadingChallenges = false;
  bool _loadingCompleted = false;
  bool _loadingBadges = false;

  Timer? _pollTimer;

  List<Challenge> get challenges => List.unmodifiable(_visibleChallenges);
  List<CompletedChallenge> get completed => List.unmodifiable(_completed);
  List<Badge> get badges => List.unmodifiable(_badges);

  void watchChallenges(String gymId, String userId) {
    debugPrint('👀 watchChallenges gymId=$gymId userId=$userId');
    _gymId = gymId.isEmpty ? null : gymId;
    _userId = userId.isEmpty ? null : userId;
    _ensurePolling();
    if (_gymId == null || _userId == null) {
      _rawChallenges.clear();
      _visibleChallenges = [];
      _completed = [];
      notifyListeners();
      return;
    }
    unawaited(_loadChallenges(force: true));
    unawaited(_loadCompleted(force: true));
  }

  void watchCompletedChallenges(String gymId, String userId) {
    debugPrint('👀 watchCompletedChallenges gymId=$gymId userId=$userId');
    _gymId = gymId.isEmpty ? null : gymId;
    _userId = userId.isEmpty ? null : userId;
    _ensurePolling();
    if (_gymId == null || _userId == null) {
      _completed = [];
      _recomputeVisible();
      return;
    }
    unawaited(_loadCompleted(force: true));
  }

  void watchBadges(String userId) {
    debugPrint('👀 watchBadges userId=$userId');
    _badgeUserId = userId.isEmpty ? null : userId;
    _ensurePolling();
    if (_badgeUserId == null) {
      _badges = [];
      notifyListeners();
      return;
    }
    unawaited(_loadBadges(force: true));
  }

  Future<void> refresh() async {
    await Future.wait([
      _loadChallenges(force: true),
      _loadCompleted(force: true),
      _loadBadges(force: true),
    ]);
  }

  Future<void> checkChallenges(String gymId, String userId, String deviceId) {
    return _repo.checkChallenges(gymId, userId, deviceId);
  }

  bool _isFresh(DateTime? ts) {
    if (ts == null) return false;
    return DateTime.now().difference(ts) < _cacheTtl;
  }

  void _ensurePolling() {
    final shouldPoll =
        (_gymId != null && _userId != null) || _badgeUserId != null;
    if (!shouldPoll) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    _pollTimer ??= Timer.periodic(_pollInterval, (_) {
      unawaited(_poll());
    });
  }

  Future<void> _poll() async {
    await _loadChallenges();
    await _loadCompleted();
    await _loadBadges();
  }

  Future<void> _loadChallenges({bool force = false}) async {
    if (_loadingChallenges || _gymId == null) {
      return;
    }
    if (!force && _isFresh(_lastChallengesFetch)) {
      return;
    }
    _loadingChallenges = true;
    try {
      final data = await _repo.fetchActiveChallenges(_gymId!);
      _rawChallenges
        ..clear()
        ..addAll(data);
      _lastChallengesFetch = DateTime.now();
      _recomputeVisible();
      debugPrint('🔄 activeChallenges=${_visibleChallenges.length}');
    } finally {
      _loadingChallenges = false;
    }
  }

  Future<void> _loadCompleted({bool force = false}) async {
    if (_loadingCompleted || _gymId == null || _userId == null) {
      return;
    }
    if (!force && _isFresh(_lastCompletedFetch)) {
      return;
    }
    _loadingCompleted = true;
    try {
      final data = await _repo.fetchCompletedChallenges(_gymId!, _userId!);
      _completed = data;
      _lastCompletedFetch = DateTime.now();
      debugPrint('🔄 completedChallenges=${_completed.length}');
      _recomputeVisible();
    } finally {
      _loadingCompleted = false;
    }
  }

  Future<void> _loadBadges({bool force = false}) async {
    if (_loadingBadges || _badgeUserId == null) {
      return;
    }
    if (!force && _isFresh(_lastBadgesFetch)) {
      return;
    }
    _loadingBadges = true;
    try {
      final data = await _repo.fetchBadges(_badgeUserId!);
      _badges = data;
      _lastBadgesFetch = DateTime.now();
      debugPrint('🔄 badges=${_badges.length}');
      notifyListeners();
    } finally {
      _loadingBadges = false;
    }
  }

  void _recomputeVisible() {
    final completedIds = _completed.map((c) => c.id).toSet();
    _visibleChallenges =
        _rawChallenges.where((c) => !completedIds.contains(c.id)).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
