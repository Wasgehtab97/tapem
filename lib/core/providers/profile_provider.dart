// lib/core/providers/profile_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/providers/auth_provider.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider();

  bool _isLoading = false;
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

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get trainingDates => List.unmodifiable(_trainingDates);
  List<DateTime> get trainingDayDates => List.unmodifiable(_trainingDayDates);
  int get totalTrainingDays => _totalTrainingDays;
  double get averageTrainingDaysPerWeek => _avgTrainingDaysPerWeek;
  String? get favoriteExerciseName => _favoriteExerciseName;
  List<FavoriteExerciseUsage> get favoriteExerciseUsages =>
      List.unmodifiable(_favoriteExerciseUsages);

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

    if (!forceRefresh &&
        _hasLoadedTrainingDates &&
        _lastLoadedUserId == userId) {
      return Future<void>.value();
    }

    return refreshTrainingDates(
      userId: userId,
      createdAt: authProv.createdAt,
      silent: false,
    );
  }

  Future<void> refreshTrainingDates({
    required String userId,
    DateTime? createdAt,
    bool silent = true,
  }) {
    if (_inFlightTrainingLoad != null &&
        _pendingTrainingUserId == userId) {
      return _inFlightTrainingLoad!;
    }

    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    } else {
      _error = null;
    }

    final future = _fetchTrainingDates(
      userId: userId,
      createdAt: createdAt,
    );
    _pendingTrainingUserId = userId;
    _inFlightTrainingLoad = future.whenComplete(() {
      _pendingTrainingUserId = null;
      _inFlightTrainingLoad = null;
    });
    return _inFlightTrainingLoad!;
  }

  Future<void> _fetchTrainingDates({
    required String userId,
    required DateTime? createdAt,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('logs')
          .where('userId', isEqualTo: userId)
          .get();

      final dateSet = <DateTime>{};
      final sessionAggregates = <String, _ExerciseAggregate>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
        dateSet.add(day);

        final sessionId = (data['sessionId'] as String?)?.trim() ?? '';
        if (sessionId.isEmpty) {
          continue;
        }

        final deviceRef = doc.reference.parent.parent;
        final deviceId = deviceRef?.id ?? '';
        final gymRef = deviceRef?.parent.parent;
        final gymId = gymRef?.id ?? '';
        if (deviceId.isEmpty || gymId.isEmpty) {
          continue;
        }

        final exerciseId = (data['exerciseId'] as String?)?.trim() ?? '';
        final key = '$gymId|$deviceId|$exerciseId';
        final aggregate = sessionAggregates.putIfAbsent(
          key,
          () => _ExerciseAggregate(
            gymId: gymId,
            deviceId: deviceId,
            exerciseId: exerciseId,
          ),
        );
        aggregate.sessionIds.add(sessionId);
      }

      _trainingDayDates = dateSet.toList()
        ..sort((a, b) => a.compareTo(b));
      _trainingDates = _trainingDayDates
          .map((dt) =>
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}')
          .toList();
      _totalTrainingDays = _trainingDates.length;
      _avgTrainingDaysPerWeek =
          _calculateAverageTrainingDaysPerWeek(createdAt);
      await _resolveFavoriteExercises(sessionAggregates.values);
      _hasLoadedTrainingDates = true;
      _lastLoadedUserId = userId;
    } catch (e, st) {
      _error = 'Fehler beim Laden der Trainingstage: ${e.toString()}';
      _hasLoadedTrainingDates = false;
      if (e is FirebaseException && e.code == 'failed-precondition') {
        elogError('FIRESTORE_FAILED_PRECONDITION', e.message ?? e.toString(), st);
      }
      debugPrintStack(
        label: 'ProfileProvider.loadTrainingDates',
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

  Future<void> _resolveFavoriteExercises(
    Iterable<_ExerciseAggregate> aggregates,
  ) async {
    if (aggregates.isEmpty) {
      _favoriteExerciseUsages = [];
      _favoriteExerciseName = null;
      return;
    }

    final sortedAggregates = aggregates
        .where((aggregate) => aggregate.sessionIds.isNotEmpty)
        .toList()
      ..sort(
        (a, b) =>
            b.sessionIds.length.compareTo(a.sessionIds.length),
      );

    final usages = <FavoriteExerciseUsage>[];

    for (final aggregate in sortedAggregates.take(5)) {
      final name = await _resolveExerciseName(aggregate);
      usages.add(
        FavoriteExerciseUsage(
          name: name,
          sessionCount: aggregate.sessionIds.length,
        ),
      );
    }

    _favoriteExerciseUsages = usages;
    _favoriteExerciseName =
        usages.isEmpty ? null : usages.first.name;
  }

  Future<String> _resolveExerciseName(_ExerciseAggregate aggregate) async {
    try {
      final deviceRef = FirebaseFirestore.instance
          .collection('gyms')
          .doc(aggregate.gymId)
          .collection('devices')
          .doc(aggregate.deviceId);
      String deviceName = aggregate.deviceId;

      final deviceSnap = await deviceRef.get();
      if (deviceSnap.exists) {
        final data = deviceSnap.data();
        final name = data?['name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          deviceName = name.trim();
        }
      }

      final exerciseId = aggregate.exerciseId;
      if (exerciseId != null && exerciseId.isNotEmpty) {
        try {
          final exerciseSnap =
              await deviceRef.collection('exercises').doc(exerciseId).get();
          final exerciseName = exerciseSnap.data()?['name'] as String?;
          if (exerciseName != null && exerciseName.trim().isNotEmpty) {
            return exerciseName.trim();
          }
        } catch (_) {}
      }

      if (deviceName.trim().isEmpty) {
        return '—';
      }

      return deviceName;
    } catch (e, st) {
      elogError('PROFILE_FAVORITE_EXERCISE', e.toString(), st);
      return '—';
    }
  }
}

class _ExerciseAggregate {
  _ExerciseAggregate({
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
  });

  final String gymId;
  final String deviceId;
  final String? exerciseId;
  final Set<String> sessionIds = <String>{};
}

class FavoriteExerciseUsage {
  FavoriteExerciseUsage({
    required this.name,
    required this.sessionCount,
  });

  final String name;
  final int sessionCount;
}
