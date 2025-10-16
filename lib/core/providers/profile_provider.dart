// lib/core/providers/profile_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/storage/profile_cache_store.dart';
import 'package:tapem/features/profile/domain/models/favorite_exercise_usage.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider();

  bool _isLoading = false;
  String? _error;
  final Set<String> _trainingDateKeys = <String>{};
  List<String> _trainingDates = [];
  List<DateTime> _trainingDayDates = [];
  int _totalTrainingDays = 0;
  double _avgTrainingDaysPerWeek = 0;
  String? _favoriteExerciseName;
  List<FavoriteExerciseUsage> _favoriteExerciseUsages = [];
  final Map<String, _ExerciseAggregate> _favoriteAggregates =
      <String, _ExerciseAggregate>{};
  DateTime? _lastProcessedLogAt;
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
  }) async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProv.userId;

    if (userId == null) {
      _error = 'Kein Benutzer gefunden';
      notifyListeners();
      return;
    }

    if (!forceRefresh &&
        _hasLoadedTrainingDates &&
        _lastLoadedUserId == userId) {
      return;
    }

    if (!forceRefresh) {
      final restored = await _restoreFromCache(
        userId: userId,
        createdAt: authProv.createdAt,
      );
      if (restored) {
        return;
      }
    }

    if (_inFlightTrainingLoad != null &&
        _pendingTrainingUserId == userId) {
      await _inFlightTrainingLoad!;
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final future = _fetchTrainingDates(
      userId: userId,
      createdAt: authProv.createdAt,
      forceRefresh: forceRefresh,
    );
    _pendingTrainingUserId = userId;
    _inFlightTrainingLoad = future.whenComplete(() {
      _pendingTrainingUserId = null;
      _inFlightTrainingLoad = null;
    });
    await _inFlightTrainingLoad!;
  }

  Future<bool> _restoreFromCache({
    required String userId,
    required DateTime? createdAt,
  }) async {
    try {
      final entry = await ProfileCacheStore.load(userId);
      if (entry == null) {
        return false;
      }
      if (entry.isExpired) {
        await ProfileCacheStore.clear(userId);
        return false;
      }

      _trainingDateKeys
        ..clear()
        ..addAll(entry.trainingDates);
      _favoriteAggregates
        ..clear()
        ..addEntries(entry.favoriteAggregates.map((agg) {
          final aggregate = _ExerciseAggregate(
            gymId: agg.gymId,
            deviceId: agg.deviceId,
            exerciseId: agg.exerciseId,
            name: agg.name,
            sessionKeys: agg.sessionKeys.toSet(),
          );
          return MapEntry(aggregate.cacheKeyValue, aggregate);
        }));
      _lastProcessedLogAt = entry.lastProcessedAt;
      await _recomputeStatistics(
        createdAt: createdAt,
        resolveNames: false,
      );
      _lastLoadedUserId = userId;
      _hasLoadedTrainingDates = true;
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrintStack(
        label: 'ProfileProvider.restoreCache',
        stackTrace: st,
      );
      return false;
    }
  }

  Future<void> _fetchTrainingDates({
    required String userId,
    required DateTime? createdAt,
    bool forceRefresh = false,
  }) async {
    try {
      if (forceRefresh) {
        _trainingDateKeys.clear();
        _favoriteAggregates.clear();
        _lastProcessedLogAt = null;
      }

      final since = forceRefresh ? null : _lastProcessedLogAt;
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collectionGroup('logs')
          .where('userId', isEqualTo: userId);
      if (since != null) {
        query = query.where(
          'timestamp',
          isGreaterThan: Timestamp.fromDate(since),
        );
      }

      final snapshot = await query.get();

      DateTime? latestTimestamp = since;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final timestampValue = data['timestamp'];
        final timestamp = timestampValue is Timestamp
            ? timestampValue.toDate()
            : timestampValue is DateTime
                ? timestampValue
                : null;
        if (timestamp == null) {
          continue;
        }
        if (latestTimestamp == null || timestamp.isAfter(latestTimestamp)) {
          latestTimestamp = timestamp;
        }

        final dayKey = _formatDayKey(
          DateTime(timestamp.year, timestamp.month, timestamp.day),
        );
        _trainingDateKeys.add(dayKey);

        final sessionId = (data['sessionId'] as String?)?.trim();
        if (sessionId == null || sessionId.isEmpty) {
          continue;
        }

        final deviceRef = doc.reference.parent.parent;
        final deviceId = deviceRef?.id ?? '';
        final gymRef = deviceRef?.parent.parent;
        final gymId = gymRef?.id ?? '';
        if (deviceId.isEmpty || gymId.isEmpty) {
          continue;
        }

        final exerciseId = (data['exerciseId'] as String?)?.trim();
        final aggregateKey = _ExerciseAggregate.cacheKey(
          gymId: gymId,
          deviceId: deviceId,
          exerciseId: exerciseId,
        );
        final aggregate = _favoriteAggregates.putIfAbsent(
          aggregateKey,
          () => _ExerciseAggregate(
            gymId: gymId,
            deviceId: deviceId,
            exerciseId:
                exerciseId == null || exerciseId.isEmpty ? null : exerciseId,
          ),
        );
        final sessionKey = '$gymId|$deviceId|$sessionId';
        aggregate.sessionKeys.add(sessionKey);
      }

      if (latestTimestamp != null) {
        _lastProcessedLogAt = latestTimestamp;
      }

      await _recomputeStatistics(createdAt: createdAt);
      _hasLoadedTrainingDates = true;
      _lastLoadedUserId = userId;

      await _persistCache(userId: userId);
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

  Future<void> _recomputeStatistics({
    required DateTime? createdAt,
    bool resolveNames = true,
  }) async {
    final parsedDates = _trainingDateKeys
        .map(_parseTrainingDateKey)
        .whereType<DateTime>()
        .toList()
      ..sort((a, b) => a.compareTo(b));
    _trainingDayDates = parsedDates;
    _trainingDates = parsedDates.map(_formatDayKey).toList();
    _totalTrainingDays = _trainingDates.length;
    _avgTrainingDaysPerWeek = _calculateAverageTrainingDaysPerWeek(createdAt);

    final aggregates = _favoriteAggregates.values
        .where((aggregate) => aggregate.sessionKeys.isNotEmpty)
        .toList()
      ..sort((a, b) => b.sessionCount.compareTo(a.sessionCount));

    final topAggregates = aggregates.take(5).toList();
    if (resolveNames) {
      await _ensureAggregateNames(topAggregates);
    }

    _favoriteExerciseUsages = topAggregates
        .map(
          (aggregate) => FavoriteExerciseUsage(
            id: aggregate.cacheKeyValue,
            name: aggregate.name.isNotEmpty ? aggregate.name : '—',
            sessionCount: aggregate.sessionCount,
          ),
        )
        .toList();
    _favoriteExerciseName =
        _favoriteExerciseUsages.isEmpty ? null : _favoriteExerciseUsages.first.name;
  }

  Future<void> _persistCache({required String userId}) async {
    try {
      final trainingDates = _trainingDateKeys.toList()..sort();
      final aggregates = _favoriteAggregates.values.toList()
        ..sort((a, b) => a.cacheKeyValue.compareTo(b.cacheKeyValue));
      final cacheAggregates = aggregates
          .map(
            (aggregate) => FavoriteExerciseAggregateCache(
              gymId: aggregate.gymId,
              deviceId: aggregate.deviceId,
              exerciseId: aggregate.exerciseId,
              name: aggregate.name,
              sessionKeys: aggregate.sessionKeys.toList()..sort(),
            ),
          )
          .toList();

      await ProfileCacheStore.save(
        userId,
        ProfileCacheEntry(
          cachedAt: DateTime.now(),
          trainingDates: trainingDates,
          favoriteAggregates: cacheAggregates,
          lastProcessedAt: _lastProcessedLogAt,
        ),
      );
    } catch (e, st) {
      debugPrintStack(
        label: 'ProfileProvider.persistCache',
        stackTrace: st,
      );
    }
  }

  DateTime? _parseTrainingDateKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) {
      return null;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  String _formatDayKey(DateTime day) {
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
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

  Future<void> _ensureAggregateNames(
    List<_ExerciseAggregate> aggregates,
  ) async {
    for (final aggregate in aggregates) {
      if (aggregate.name.isEmpty) {
        aggregate.name = await _resolveExerciseName(aggregate);
      }
    }
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
            aggregate.name = exerciseName.trim();
            return aggregate.name;
          }
        } catch (_) {}
      }

      if (deviceName.trim().isEmpty) {
        aggregate.name = '—';
        return aggregate.name;
      }

      aggregate.name = deviceName;
      return aggregate.name;
    } catch (e, st) {
      elogError('PROFILE_FAVORITE_EXERCISE', e.toString(), st);
      aggregate.name = '—';
      return aggregate.name;
    }
  }
}

class _ExerciseAggregate {
  _ExerciseAggregate({
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
    String? name,
    Set<String>? sessionKeys,
  })  : name = name ?? '',
        sessionKeys = sessionKeys ?? <String>{};

  final String gymId;
  final String deviceId;
  final String? exerciseId;
  String name;
  final Set<String> sessionKeys;

  int get sessionCount => sessionKeys.length;

  String get cacheKeyValue => cacheKey(
        gymId: gymId,
        deviceId: deviceId,
        exerciseId: exerciseId,
      );

  static String cacheKey({
    required String gymId,
    required String deviceId,
    String? exerciseId,
  }) {
    return '$gymId|$deviceId|${exerciseId ?? ''}';
  }
}

