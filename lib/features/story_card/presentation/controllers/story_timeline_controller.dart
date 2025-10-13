import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/story_analytics_service.dart';
import '../../data/story_timeline_repository.dart';
import '../../domain/story_timeline_entry.dart';
import '../../domain/story_timeline_filter.dart';

class StoryTimelineController extends ChangeNotifier {
  StoryTimelineController({
    required this.userId,
    StoryTimelineRepository? repository,
    StoryAnalyticsService? analytics,
  })  : _repository = repository ?? StoryTimelineRepository(),
        _analytics = analytics ?? StoryAnalyticsService();

  final String userId;
  final StoryTimelineRepository _repository;
  final StoryAnalyticsService _analytics;

  final List<StoryTimelineEntry> _entries = [];
  StoryTimelineFilter _filter = const StoryTimelineFilter();
  bool _isLoading = false;
  bool _hasMore = true;
  Object? _error;
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  StoryTimelineMetrics? _metrics;
  StreamSubscription<StoryTimelineMetrics>? _metricsSub;

  StoryTimelineFilter get filter => _filter;
  UnmodifiableListView<StoryTimelineEntry> get entries => UnmodifiableListView(_entries);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  Object? get error => _error;
  StoryTimelineMetrics? get metrics => _metrics;

  Future<void> init() async {
    if (userId.isEmpty) {
      _entries.clear();
      _hasMore = false;
      notifyListeners();
      return;
    }
    _metricsSub ??= _repository.watchMetrics(userId).listen((event) {
      _metrics = event;
      notifyListeners();
    });
    await _analytics.markTimelineOpened(userId);
    await refresh(preferCache: true);
  }

  Future<void> refresh({bool preferCache = false}) async {
    if (userId.isEmpty) {
      _entries.clear();
      _hasMore = false;
      notifyListeners();
      return;
    }
    _setLoading(true);
    _error = null;
    try {
      final page = await _repository.fetchStories(
        userId: userId,
        filter: _filter,
        limit: 20,
        preferCache: preferCache,
      );
      _entries
        ..clear()
        ..addAll(page.entries);
      _hasMore = page.hasMore;
      _lastDocument = page.lastDocument;
    } catch (error, stack) {
      debugPrint('StoryTimelineController.refresh error: $error\n$stack');
      _error = error;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoading || userId.isEmpty) {
      return;
    }
    _setLoading(true);
    _error = null;
    try {
      final page = await _repository.fetchStories(
        userId: userId,
        filter: _filter,
        startAfter: _lastDocument,
        limit: 20,
      );
      _entries.addAll(page.entries);
      _hasMore = page.hasMore;
      _lastDocument = page.lastDocument;
    } catch (error, stack) {
      debugPrint('StoryTimelineController.loadMore error: $error\n$stack');
      _error = error;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> applyFilter(StoryTimelineFilter filter) async {
    if (filter == _filter) {
      return;
    }
    _filter = filter;
    notifyListeners();
    await refresh(preferCache: true);
  }

  void updateGym(String? gymId) {
    final updated = _filter.copyWith(gymId: gymId);
    if (updated != _filter) {
      _filter = updated;
      notifyListeners();
      unawaited(refresh(preferCache: true));
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _metricsSub?.cancel();
    super.dispose();
  }
}
