// lib/core/providers/profile_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/models/favorite_exercise_usage.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/services/training_summary_service.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({TrainingSummaryService? summaryService})
      : _summaryService = summaryService ?? TrainingSummaryService();

  final TrainingSummaryService _summaryService;
  // Cached summary snapshots ensure that hot restarts do not trigger expensive
  // collectionGroup reads. The service enforces a 10-minute TTL so the data
  // stays reasonably fresh without hammering Firestore.
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  List<String> _trainingDates = [];
  List<DateTime> _trainingDayDates = [];
  int _totalTrainingDays = 0;
  double _avgTrainingDaysPerWeek = 0;
  String? _favoriteExerciseName;
  List<FavoriteExerciseUsage> _favoriteExerciseUsages = [];
  String? _lastLoadedUserId;
  String? _pendingTrainingUserId;
  Future<void>? _inFlightTrainingLoad;
  bool _hasLoadedTrainingDates = false;
  bool _hasMoreSummaries = true;
  List<TrainingSummary> _summaries = [];
  bool _hasSummaries = false;
  bool _lastLoadFromCache = false;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  List<String> get trainingDates => List.unmodifiable(_trainingDates);
  List<DateTime> get trainingDayDates => List.unmodifiable(_trainingDayDates);
  int get totalTrainingDays => _totalTrainingDays;
  double get averageTrainingDaysPerWeek => _avgTrainingDaysPerWeek;
  String? get favoriteExerciseName => _favoriteExerciseName;
  List<FavoriteExerciseUsage> get favoriteExerciseUsages =>
      List.unmodifiable(_favoriteExerciseUsages);
  bool get hasMoreSummaries => _hasMoreSummaries;
  List<TrainingSummary> get summaries => List.unmodifiable(_summaries);
  bool get hasSummaries => _hasSummaries;
  bool get lastLoadFromCache => _lastLoadFromCache;

  /// Lädt alle Trainingstage (YYYY-MM-DD) des aktuellen Users.
  Future<void> loadTrainingDates(
    BuildContext context, {
    bool forceRefresh = false,
  }) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProv.userId;

    if (userId == null) {
      _error = 'Kein Benutzer gefunden';
      notifyListeners();
      return Future<void>.value();
    }

    if (_lastLoadedUserId != null && _lastLoadedUserId != userId) {
      _resetState();
    }

    if (!forceRefresh &&
        _hasLoadedTrainingDates &&
        _lastLoadedUserId == userId) {
      return Future<void>.value();
    }

    if (_inFlightTrainingLoad != null &&
        _pendingTrainingUserId == userId) {
      return _inFlightTrainingLoad!;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final future = _fetchTrainingSummaries(
      userId: userId,
      createdAt: authProv.createdAt,
      forceRefresh: forceRefresh,
      loadMore: false,
    );
    _pendingTrainingUserId = userId;
    _inFlightTrainingLoad = future.whenComplete(() {
      _pendingTrainingUserId = null;
      _inFlightTrainingLoad = null;
    });
    return _inFlightTrainingLoad!;
  }

  Future<void> loadMoreTrainingSummaries(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProv.userId;
    if (userId == null || !_hasMoreSummaries || _isLoadingMore) {
      return Future<void>.value();
    }

    _isLoadingMore = true;
    notifyListeners();

    final future = _fetchTrainingSummaries(
      userId: userId,
      createdAt: authProv.createdAt,
      forceRefresh: false,
      loadMore: true,
    );

    return future.whenComplete(() {
      _isLoadingMore = false;
      notifyListeners();
    });
  }

  void _resetState() {
    _trainingDates = [];
    _trainingDayDates = [];
    _totalTrainingDays = 0;
    _avgTrainingDaysPerWeek = 0;
    _favoriteExerciseName = null;
    _favoriteExerciseUsages = [];
    _summaries = [];
    _hasMoreSummaries = true;
    _hasSummaries = false;
    _lastLoadFromCache = false;
    _hasLoadedTrainingDates = false;
  }

  Future<void> refreshSummaries(
    BuildContext context, {
    bool forceRemote = false,
  }) {
    return loadTrainingDates(
      context,
      forceRefresh: forceRemote,
    );
  }

  TrainingSummary? summaryForDateKey(String dateKey) {
    for (final summary in _summaries) {
      if (summary.dateKey == dateKey) {
        return summary;
      }
    }
    return null;
  }

  Future<void> _fetchTrainingSummaries({
    required String userId,
    required DateTime? createdAt,
    required bool forceRefresh,
    required bool loadMore,
  }) async {
    try {
      final state = await _summaryService.loadSummaries(
        userId: userId,
        forceRefresh: forceRefresh,
        loadMore: loadMore,
      );

      _summaries = state.entries;
      _lastLoadFromCache = state.fromCache;
      _trainingDayDates = _summaries
          .map((summary) =>
              DateTime(summary.date.year, summary.date.month, summary.date.day))
          .toSet()
          .toList()
        ..sort((a, b) => a.compareTo(b));
      _trainingDates = _trainingDayDates
          .map((dt) =>
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}')
          .toList();
      _totalTrainingDays = state.aggregate.trainingDayCount;
      _avgTrainingDaysPerWeek = state.aggregate.averageTrainingDaysPerWeek > 0
          ? state.aggregate.averageTrainingDaysPerWeek
          : _calculateAverageTrainingDaysPerWeek(createdAt);
      _favoriteExerciseUsages = state.aggregate.favoriteExercises;
      _favoriteExerciseName =
          _favoriteExerciseUsages.isEmpty ? null : _favoriteExerciseUsages.first.name;
      _hasLoadedTrainingDates = true;
      _lastLoadedUserId = userId;
      _hasMoreSummaries = state.hasMore;
      _hasSummaries =
          state.entries.isNotEmpty || state.aggregate.trainingDayCount > 0;
    } catch (e, st) {
      _error = 'Fehler beim Laden der Trainingstage: ${e.toString()}';
      _hasLoadedTrainingDates = false;
      _hasMoreSummaries = false;
      _hasSummaries = false;
      elogError('PROFILE_PROVIDER_TRAINING_SUMMARY', e.toString(), st);
      debugPrintStack(
        label: 'ProfileProvider.loadTrainingSummaries',
        stackTrace: st,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double _calculateAverageTrainingDaysPerWeek(
    DateTime? createdAt, {
    DateTime Function()? nowProvider,
  }) {
    if (_trainingDayDates.isEmpty) {
      return 0;
    }

    final normalizedCreatedAt = createdAt == null
        ? _trainingDayDates.first
        : DateTime(createdAt.year, createdAt.month, createdAt.day);
    final firstMonday = _firstMondayAfter(normalizedCreatedAt);
    final now = (nowProvider ?? DateTime.now).call();
    final today = DateTime(now.year, now.month, now.day);
    final daysSinceSunday = today.weekday % 7;
    final lastCompletedWeekEnd = today.subtract(
      Duration(days: daysSinceSunday == 0 ? 7 : daysSinceSunday),
    );

    if (lastCompletedWeekEnd
        .isBefore(firstMonday.add(const Duration(days: 6)))) {
      return 0;
    }

    final filteredDays = _trainingDayDates.where((day) {
      return !day.isBefore(firstMonday) && !day.isAfter(lastCompletedWeekEnd);
    }).toList();

    if (filteredDays.isEmpty) {
      return 0;
    }

    final completedWeeks =
        (lastCompletedWeekEnd.difference(firstMonday).inDays + 1) ~/ 7;
    if (completedWeeks <= 0) {
      return 0;
    }

    return filteredDays.length / completedWeeks;
  }

  @visibleForTesting
  void setTrainingDayDatesForTest(List<DateTime> days) {
    _trainingDayDates = List<DateTime>.from(days)
      ..sort((a, b) => a.compareTo(b));
  }

  @visibleForTesting
  double calculateAverageTrainingDaysPerWeekForTest(
    DateTime? createdAt, {
    DateTime Function()? nowProvider,
  }) {
    return _calculateAverageTrainingDaysPerWeek(
      createdAt,
      nowProvider: nowProvider,
    );
  }

  DateTime _firstMondayAfter(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final offset = (DateTime.monday - normalized.weekday + 7) % 7;
    final daysToAdd = offset == 0 ? 7 : offset;
    return normalized.add(Duration(days: daysToAdd));
  }
}

class _LegacyImportResult {
  const _LegacyImportResult({
    required this.trainingDays,
    required this.exerciseCounts,
    required this.sessionCount,
    required this.firstWorkout,
    required this.lastWorkout,
  });

  final Set<DateTime> trainingDays;
  final Map<String, int> exerciseCounts;
  final int sessionCount;
  final DateTime? firstWorkout;
  final DateTime? lastWorkout;
}
