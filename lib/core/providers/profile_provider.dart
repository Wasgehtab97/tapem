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
  final Map<String, _ExerciseAggregate> _exerciseAggregates = {};
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

  DateTime? firstUsageForDevice(String gymId, String deviceId) {
    return _exerciseAggregates[_aggregateKey(gymId, deviceId, null)]?.firstTimestamp;
  }

  DateTime? firstUsageForExercise(
    String gymId,
    String deviceId,
    String? exerciseId,
  ) {
    return _exerciseAggregates[_aggregateKey(gymId, deviceId, exerciseId)]
        ?.firstTimestamp;
  }

  double? bestE1rmBefore(
    String gymId,
    String deviceId,
    String? exerciseId,
    DateTime day,
  ) {
    final key = _aggregateKey(gymId, deviceId, exerciseId);
    return _exerciseAggregates[key]?.bestE1rmBefore(_formatDayKey(day));
  }

  double? bestE1rmOn(
    String gymId,
    String deviceId,
    String? exerciseId,
    DateTime day,
  ) {
    final key = _aggregateKey(gymId, deviceId, exerciseId);
    return _exerciseAggregates[key]?.bestE1rmOn(_formatDayKey(day));
  }

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

    if (_inFlightTrainingLoad != null &&
        _pendingTrainingUserId == userId) {
      return _inFlightTrainingLoad!;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final future = _fetchTrainingDates(
      userId: userId,
      createdAt: authProv.createdAt,
    );
    _pendingTrainingUserId = userId;
    _inFlightTrainingLoad = future.whenComplete(() {
      _pendingTrainingUserId = null;
      _inFlightTrainingLoad = null;
    });
    return _inFlightTrainingLoad!;
  }

  String _aggregateKey(String gymId, String deviceId, String? exerciseId) {
    final trimmed = exerciseId?.trim();
    final normalized = (trimmed == null || trimmed.isEmpty) ? '' : trimmed;
    return '$gymId|$deviceId|$normalized';
  }

  String _formatDayKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
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
      _exerciseAggregates.clear();

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
        final weight = (data['weight'] as num?)?.toDouble();
        final reps = (data['reps'] as num?)?.toInt() ?? 0;
        final dropWeightKg = (data['dropWeightKg'] as num?)?.toDouble();
        final dropReps = (data['dropReps'] as num?)?.toInt();
        final isBodyweight = data['isBodyweight'] as bool? ?? false;

        final deviceAggregate = _exerciseAggregates.putIfAbsent(
          _aggregateKey(gymId, deviceId, null),
          () => _ExerciseAggregate(
            gymId: gymId,
            deviceId: deviceId,
            exerciseId: null,
          ),
        );
        deviceAggregate.register(
          sessionId: sessionId,
          timestamp: timestamp,
          weight: weight,
          reps: reps,
          dropWeightKg: dropWeightKg,
          dropReps: dropReps,
          isBodyweight: isBodyweight,
        );

        final normalizedExerciseId = exerciseId.isEmpty ? null : exerciseId;
        if (normalizedExerciseId != null) {
          final exerciseAggregate = _exerciseAggregates.putIfAbsent(
            _aggregateKey(gymId, deviceId, normalizedExerciseId),
            () => _ExerciseAggregate(
              gymId: gymId,
              deviceId: deviceId,
              exerciseId: normalizedExerciseId,
            ),
          );
          exerciseAggregate.register(
            sessionId: sessionId,
            timestamp: timestamp,
            weight: weight,
            reps: reps,
            dropWeightKg: dropWeightKg,
            dropReps: dropReps,
            isBodyweight: isBodyweight,
          );
        }
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
      await _resolveFavoriteExercises(_exerciseAggregates.values);
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
    final deviceNameCache = <String, String>{};
    final exerciseNameCache = <String, String>{};

    for (final aggregate in sortedAggregates.take(5)) {
      final name = await _resolveExerciseName(
        aggregate,
        deviceNameCache: deviceNameCache,
        exerciseNameCache: exerciseNameCache,
      );
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

  Future<String> _resolveExerciseName(
    _ExerciseAggregate aggregate, {
    required Map<String, String> deviceNameCache,
    required Map<String, String> exerciseNameCache,
  }) async {
    try {
      final deviceRef = FirebaseFirestore.instance
          .collection('gyms')
          .doc(aggregate.gymId)
          .collection('devices')
          .doc(aggregate.deviceId);
      final deviceKey = '${aggregate.gymId}|${aggregate.deviceId}';
      String deviceName = deviceNameCache[deviceKey] ?? aggregate.deviceId;
      if (!deviceNameCache.containsKey(deviceKey)) {
        try {
          final deviceSnap = await deviceRef.get();
          if (deviceSnap.exists) {
            final data = deviceSnap.data();
            final name = data?['name'] as String?;
            if (name != null && name.trim().isNotEmpty) {
              deviceName = name.trim();
            }
          }
        } catch (_) {}
        deviceNameCache[deviceKey] = deviceName;
      }

      final exerciseId = aggregate.exerciseId;
      if (exerciseId != null && exerciseId.isNotEmpty) {
        final exerciseKey = '$deviceKey|$exerciseId';
        String? exerciseName = exerciseNameCache[exerciseKey];
        if (exerciseName == null) {
          try {
            final exerciseSnap =
                await deviceRef.collection('exercises').doc(exerciseId).get();
            final resolved = exerciseSnap.data()?['name'] as String?;
            if (resolved != null && resolved.trim().isNotEmpty) {
              exerciseName = resolved.trim();
            }
          } catch (_) {}
          if (exerciseName != null) {
            exerciseNameCache[exerciseKey] = exerciseName;
          }
        }
        if (exerciseName != null && exerciseName.trim().isNotEmpty) {
          return exerciseName;
        }
      }

      final normalizedName = deviceName.trim();
      if (normalizedName.isEmpty) {
        return '—';
      }

      return normalizedName;
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
  DateTime? firstTimestamp;
  DateTime? lastTimestamp;
  final Map<String, double> bestE1rmByDay = <String, double>{};

  void register({
    required String sessionId,
    required DateTime timestamp,
    double? weight,
    required int reps,
    double? dropWeightKg,
    int? dropReps,
    required bool isBodyweight,
  }) {
    sessionIds.add(sessionId);
    if (firstTimestamp == null || timestamp.isBefore(firstTimestamp!)) {
      firstTimestamp = timestamp;
    }
    if (lastTimestamp == null || timestamp.isAfter(lastTimestamp!)) {
      lastTimestamp = timestamp;
    }
    _updateE1rm(timestamp, _computeE1rm(weight, reps, isBodyweight));
    if (dropWeightKg != null && dropReps != null && dropReps > 0) {
      _updateE1rm(timestamp, _computeE1rm(dropWeightKg, dropReps, false));
    }
  }

  void _updateE1rm(DateTime timestamp, double? value) {
    if (value == null || value.isNaN || value.isInfinite || value <= 0) {
      return;
    }
    final key = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-'
        '${timestamp.day.toString().padLeft(2, '0')}';
    final current = bestE1rmByDay[key];
    if (current == null || value > current) {
      bestE1rmByDay[key] = value;
    }
  }

  double? bestE1rmBefore(String dayKey) {
    double? best;
    for (final entry in bestE1rmByDay.entries) {
      if (entry.key.compareTo(dayKey) < 0) {
        if (best == null || entry.value > best) {
          best = entry.value;
        }
      }
    }
    return best;
  }

  double? bestE1rmOn(String dayKey) => bestE1rmByDay[dayKey];

  double? _computeE1rm(double? weight, int reps, bool isBodyweight) {
    if (weight == null) {
      return null;
    }
    if (isBodyweight) {
      // Bodyweight Bewegungen ohne zusätzliches Gewicht lassen sich nicht
      // zuverlässig als 1RM schätzen.
      if (weight.abs() < 0.01 || reps <= 0) {
        return null;
      }
    }
    if (reps <= 0 || weight <= 0) {
      return null;
    }
    return weight * (1 + reps / 30.0);
  }
}

class FavoriteExerciseUsage {
  FavoriteExerciseUsage({
    required this.name,
    required this.sessionCount,
  });

  final String name;
  final int sessionCount;
}
