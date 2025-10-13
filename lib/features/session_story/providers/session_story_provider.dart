import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/features/session_story/data/session_story_service.dart';
import 'package:tapem/features/session_story/domain/models/session_story.dart';

class SessionStoryProvider extends ChangeNotifier {
  final SessionStoryService _service;
  final Map<String, SessionStory?> _cache = {};
  final Map<String, Object> _errors = {};
  StreamSubscription<SessionDayCompleted>? _subscription;
  WorkoutSessionDurationService? _attachedService;
  ProfileProvider? _profileProvider;
  String? _currentUserId;
  String? _currentGymId;
  DateTime? _userCreatedAt;
  SessionStory? _pendingPopup;
  bool _showPopup = false;
  bool _dialogVisible = false;
  bool _disposed = false;

  SessionStoryProvider({SessionStoryService? service})
      : _service = service ?? SessionStoryService();

  SessionStory? get pendingPopup => _showPopup ? _pendingPopup : null;
  bool get showPopup => _showPopup && _pendingPopup != null && !_dialogVisible;
  bool get dialogVisible => _dialogVisible;

  void updateContext({
    required WorkoutSessionDurationService timerService,
    String? userId,
    String? gymId,
    ProfileProvider? profileProvider,
    DateTime? userCreatedAt,
  }) {
    if (_attachedService != timerService) {
      _subscription?.cancel();
      _attachedService = timerService;
      _subscription = timerService.dayCompletedStream.listen(_handleDayCompleted);
    }
    if (_currentUserId != userId || _currentGymId != gymId) {
      _cache.clear();
      _errors.clear();
      _pendingPopup = null;
      _showPopup = false;
    }
    _currentUserId = userId;
    _currentGymId = gymId;
    _profileProvider = profileProvider;
    _userCreatedAt = userCreatedAt;
    // Mark parameters as intentionally unused while keeping signature extensible.
    if (userId != null || gymId != null) {
      debugPrint('SessionStoryProvider context updated for $userId@$gymId');
    }
  }

  Future<SessionStory?> ensureStory({
    required String gymId,
    required String userId,
    required String dayKey,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _cacheKey(gymId, userId, dayKey);
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }
    try {
      final story = await _service.buildStory(
        gymId: gymId,
        userId: userId,
        dayKey: dayKey,
      );
      _cache[cacheKey] = story;
      if (story != null) {
        _errors.remove(cacheKey);
      }
      notifyListeners();
      return story;
    } catch (e, st) {
      debugPrint('SessionStoryProvider.ensureStory error: $e\n$st');
      _errors[cacheKey] = e;
      return null;
    }
  }

  SessionStory? getCachedStory(String gymId, String userId, String dayKey) {
    final cacheKey = _cacheKey(gymId, userId, dayKey);
    return _cache[cacheKey];
  }

  Object? getError(String gymId, String userId, String dayKey) {
    final cacheKey = _cacheKey(gymId, userId, dayKey);
    return _errors[cacheKey];
  }

  void presentStory(SessionStory story) {
    _pendingPopup = story;
    _showPopup = true;
    notifyListeners();
  }

  void markDialogVisible(bool visible) {
    if (_dialogVisible == visible) return;
    _dialogVisible = visible;
    if (!visible && _showPopup) {
      _showPopup = false;
    }
    notifyListeners();
  }

  void dismissPopup() {
    _pendingPopup = null;
    _showPopup = false;
    notifyListeners();
  }

  Future<void> _handleDayCompleted(SessionDayCompleted event) async {
    const retryDelays = <Duration>[
      Duration(seconds: 0),
      Duration(seconds: 5),
      Duration(seconds: 15),
      Duration(seconds: 30),
    ];
    for (final delay in retryDelays) {
      if (_disposed) return;
      if (delay.inMilliseconds > 0) {
        await Future.delayed(delay);
        if (_disposed) return;
      }
      final story = await ensureStory(
        gymId: event.gymId,
        userId: event.uid,
        dayKey: event.dayKey,
        forceRefresh: true,
      );
      if (story != null) {
        _pendingPopup = story;
        _showPopup = true;
        notifyListeners();
        break;
      }
    }
    unawaited(_profileProvider?.refreshTrainingDates(
      userId: event.uid,
      createdAt: _userCreatedAt,
      silent: true,
    ));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _disposed = true;
    super.dispose();
  }

  String _cacheKey(String gymId, String userId, String dayKey) =>
      '$gymId::$userId::$dayKey';
}
