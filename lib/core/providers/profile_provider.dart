// lib/core/providers/profile_provider.dart

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/models/favorite_exercise_usage.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/storage/profile_cache_store.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({
    FirebaseFirestore? firestore,
    ProfileCacheStore? cache,
    DateTime Function()? nowProvider,
    Duration? cacheTtl,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cache = cache ?? const ProfileCacheStore(),
        _nowProvider = nowProvider ?? DateTime.now,
        _cacheTtl = cacheTtl ?? const Duration(hours: 24);

  final FirebaseFirestore _firestore;
  final ProfileCacheStore _cache;
  final DateTime Function() _nowProvider;
  final Duration _cacheTtl;

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
  String? _pendingTrainingGymId;
  String? _lastLoadedGymId;
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
    String? gymId,
  }) async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProv.userId;

    if (userId == null) {
      _error = 'Kein Benutzer gefunden';
      notifyListeners();
      return;
    }

    String? resolvedGymId = gymId;
    if (resolvedGymId == null) {
      try {
        resolvedGymId =
            Provider.of<GymProvider>(context, listen: false).currentGymId;
      } catch (_) {
        resolvedGymId = null;
      }
    }
    if (resolvedGymId != null && resolvedGymId.trim().isEmpty) {
      resolvedGymId = null;
    }

    if (!forceRefresh &&
        _hasLoadedTrainingDates &&
        _lastLoadedUserId == userId &&
        _lastLoadedGymId == resolvedGymId) {
      return;
    }

    if (_inFlightTrainingLoad != null &&
        _pendingTrainingUserId == userId &&
        _pendingTrainingGymId == resolvedGymId) {
      await _inFlightTrainingLoad;
      return;
    }

    final hasFreshCache = await _tryLoadFromCache(
      userId,
      forceRefresh,
      resolvedGymId,
    );
    if (hasFreshCache) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final future = _loadFromFirestore(
      userId: userId,
      createdAt: authProv.createdAt,
      gymId: resolvedGymId,
    );
    _pendingTrainingUserId = userId;
    _pendingTrainingGymId = resolvedGymId;
    _inFlightTrainingLoad = future.whenComplete(() {
      _pendingTrainingUserId = null;
      _pendingTrainingGymId = null;
      _inFlightTrainingLoad = null;
    });
    await _inFlightTrainingLoad;
  }

  Future<bool> _tryLoadFromCache(
    String userId,
    bool forceRefresh,
    String? gymId,
  ) async {
    if (forceRefresh) {
      return false;
    }

    final cached = await _cache.read(userId);
    if (cached == null) {
      return false;
    }

    _assignEntry(cached, userId, gymId: gymId);
    final now = _nowProvider();
    final isGymMismatch =
        gymId != null && cached.favoriteExercisesGymId != gymId;
    final isExpired = cached.isExpired(now, _cacheTtl) || isGymMismatch;
    _error = null;
    _isLoading = isExpired;
    notifyListeners();
    return !isExpired;
  }

  Future<void> _loadFromFirestore({
    required String userId,
    required DateTime? createdAt,
    String? gymId,
  }) async {
    try {
      final entry = await _fetchTrainingDates(
        userId: userId,
        createdAt: createdAt,
        now: _nowProvider(),
        gymId: gymId,
      );
      _assignEntry(entry, userId, gymId: gymId);
      _error = null;
      await _cache.write(userId, entry);
      _isLoading = false;
      notifyListeners();
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
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ProfileCacheEntry> _fetchTrainingDates({
    required String userId,
    required DateTime? createdAt,
    required DateTime now,
    String? gymId,
  }) async {
    final aggregated = await _fetchFromAggregates(
      userId: userId,
      createdAt: createdAt,
      now: now,
      gymId: gymId,
    );
    if (aggregated != null) {
      return aggregated;
    }

    return _fetchFromLegacyLogs(
      userId: userId,
      createdAt: createdAt,
      now: now,
      gymId: gymId,
    );
  }

  Future<ProfileCacheEntry?> _fetchFromAggregates({
    required String userId,
    required DateTime? createdAt,
    required DateTime now,
    String? gymId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('trainingDayXP')
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final dateSet = <DateTime>{};
      for (final doc in snapshot.docs) {
        final day = _parseDayKey(doc.id);
        if (day != null) {
          dateSet.add(day);
        }
      }

      final trainingDayDates = dateSet.toList()
        ..sort((a, b) => a.compareTo(b));
      final trainingDates = trainingDayDates
          .map((dt) =>
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}')
          .toList();
      final totalTrainingDays = trainingDayDates.length;
      final avgTrainingDaysPerWeek = _calculateAverageTrainingDaysPerWeek(
        trainingDayDates,
        createdAt,
        nowProvider: () => now,
      );
      final favoriteExercises = await _loadFavoriteExercisesFromAggregates(
        userId: userId,
        gymId: gymId,
      );

      return ProfileCacheEntry(
        trainingDates: trainingDates,
        trainingDayDates: trainingDayDates,
        totalTrainingDays: totalTrainingDays,
        averageTrainingDaysPerWeek: avgTrainingDaysPerWeek,
        favoriteExerciseName: favoriteExercises.favoriteExerciseName,
        favoriteExerciseUsages: favoriteExercises.usages,
        favoriteExercisesGymId: gymId,
        cachedAt: now,
      );
    } catch (e, st) {
      elogError('PROFILE_AGGREGATE_FETCH_FAILED', e.toString(), st, {
        'userId': userId,
        'gymId': gymId,
      });
      return null;
    }
  }

  Future<ProfileCacheEntry> _fetchFromLegacyLogs({
    required String userId,
    required DateTime? createdAt,
    required DateTime now,
    String? gymId,
  }) async {
    final snapshot = await _firestore
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
      final gymDocId = gymRef?.id ?? '';
      if (deviceId.isEmpty || gymDocId.isEmpty) {
        continue;
      }

      final exerciseId = (data['exerciseId'] as String?)?.trim() ?? '';
      final key = '$gymDocId|$deviceId|$exerciseId';
      final aggregate = sessionAggregates.putIfAbsent(
        key,
        () => _ExerciseAggregate(
          gymId: gymDocId,
          deviceId: deviceId,
          exerciseId: exerciseId,
        ),
      );
      aggregate.sessionIds.add(sessionId);
    }

    final trainingDayDates = dateSet.toList()
      ..sort((a, b) => a.compareTo(b));
    final trainingDates = trainingDayDates
        .map((dt) =>
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}')
        .toList();
    final totalTrainingDays = trainingDayDates.length;
    final avgTrainingDaysPerWeek = _calculateAverageTrainingDaysPerWeek(
      trainingDayDates,
      createdAt,
      nowProvider: () => now,
    );
    final favoriteExercises = await _resolveFavoriteExercises(
      sessionAggregates.values,
    );

    return ProfileCacheEntry(
      trainingDates: trainingDates,
      trainingDayDates: trainingDayDates,
      totalTrainingDays: totalTrainingDays,
      averageTrainingDaysPerWeek: avgTrainingDaysPerWeek,
      favoriteExerciseName: favoriteExercises.favoriteExerciseName,
      favoriteExerciseUsages: favoriteExercises.usages,
      favoriteExercisesGymId: gymId,
      cachedAt: now,
    );
  }

  DateTime? _parseDayKey(String key) {
    if (key.length == 8) {
      final year = int.tryParse(key.substring(0, 4));
      final month = int.tryParse(key.substring(4, 6));
      final day = int.tryParse(key.substring(6, 8));
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.tryParse(key);
  }

  Future<_FavoriteExercisesResult> _loadFavoriteExercisesFromAggregates({
    required String userId,
    String? gymId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('favorites')
          .get();
      final data = doc.data();
      if (data != null) {
        final favoriteName = (data['favoriteExerciseName'] as String?)?.trim();
        final usages = (data['usages'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(FavoriteExerciseUsage.fromJson)
                .toList() ??
            const <FavoriteExerciseUsage>[];
        if (favoriteName != null && favoriteName.isNotEmpty ||
            usages.isNotEmpty) {
          return _FavoriteExercisesResult(
            favoriteExerciseName:
                favoriteName != null && favoriteName.isNotEmpty
                    ? favoriteName
                    : null,
            usages: usages,
          );
        }
      }
    } catch (e, st) {
      elogError('PROFILE_FAVORITES_AGGREGATE_FAILED', e.toString(), st, {
        'userId': userId,
        'gymId': gymId,
      });
    }

    if (gymId != null && gymId.isNotEmpty) {
      final leaderboard = await _loadFavoritesFromLeaderboard(userId, gymId);
      if (leaderboard.usages.isNotEmpty) {
        return leaderboard;
      }
    }
    return const _FavoriteExercisesResult();
  }

  Future<_FavoriteExercisesResult> _loadFavoritesFromLeaderboard(
    String userId,
    String gymId,
  ) async {
    try {
      final devicesSnap = await _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('devices')
          .get();
      if (devicesSnap.docs.isEmpty) {
        return const _FavoriteExercisesResult();
      }

      final usages = await Future.wait(
        devicesSnap.docs.map((deviceDoc) async {
          final deviceData = deviceDoc.data();
          final deviceName = (deviceData?['name'] as String?)?.trim();
          final leaderboardDoc = await deviceDoc.reference
              .collection('leaderboard')
              .doc(userId)
              .get();
          final lbData = leaderboardDoc.data();
          if (lbData == null) {
            return null;
          }

          int? sessions;
          final sessionField = lbData['sessions'];
          if (sessionField is num) {
            sessions = sessionField.toInt();
          }
          if (sessions == null) {
            final xp = (lbData['xp'] as num?)?.toInt();
            if (xp != null && xp > 0) {
              sessions = max(1, (xp / 50).round());
            }
          }
          if (sessions == null || sessions <= 0) {
            return null;
          }

          final resolvedName =
              (deviceName != null && deviceName.isNotEmpty)
                  ? deviceName
                  : deviceDoc.id;
          return FavoriteExerciseUsage(
            name: resolvedName,
            sessionCount: sessions,
          );
        }),
      );

      final filtered = usages.whereType<FavoriteExerciseUsage>().toList()
        ..sort((a, b) => b.sessionCount.compareTo(a.sessionCount));
      final top = filtered.take(5).toList();
      return _FavoriteExercisesResult(
        favoriteExerciseName: top.isEmpty ? null : top.first.name,
        usages: top,
      );
    } catch (e, st) {
      elogError('PROFILE_FAVORITES_LEADERBOARD_FAILED', e.toString(), st, {
        'userId': userId,
        'gymId': gymId,
      });
      return const _FavoriteExercisesResult();
    }
  }

  void _assignEntry(
    ProfileCacheEntry entry,
    String userId, {
    String? gymId,
  }) {
    _trainingDates = List<String>.from(entry.trainingDates);
    _trainingDayDates = List<DateTime>.from(entry.trainingDayDates)
      ..sort((a, b) => a.compareTo(b));
    _totalTrainingDays = entry.totalTrainingDays;
    _avgTrainingDaysPerWeek = entry.averageTrainingDaysPerWeek;
    _favoriteExerciseName = entry.favoriteExerciseName;
    _favoriteExerciseUsages =
        List<FavoriteExerciseUsage>.from(entry.favoriteExerciseUsages);
    _hasLoadedTrainingDates = true;
    _lastLoadedUserId = userId;
    _lastLoadedGymId = gymId ?? entry.favoriteExercisesGymId;
  }

  double _calculateAverageTrainingDaysPerWeek(
    List<DateTime> trainingDayDates,
    DateTime? createdAt, {
    DateTime Function()? nowProvider,
  }) {
    if (trainingDayDates.isEmpty) {
      return 0;
    }

    final normalizedCreatedAt = createdAt == null
        ? trainingDayDates.first
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

    final filteredDays = trainingDayDates.where((day) {
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
      _trainingDayDates,
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

  Future<_FavoriteExercisesResult> _resolveFavoriteExercises(
    Iterable<_ExerciseAggregate> aggregates,
  ) async {
    if (aggregates.isEmpty) {
      return const _FavoriteExercisesResult();
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

    return _FavoriteExercisesResult(
      favoriteExerciseName: usages.isEmpty ? null : usages.first.name,
      usages: usages,
    );
  }

  Future<String> _resolveExerciseName(_ExerciseAggregate aggregate) async {
    try {
      final deviceRef = _firestore
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

class _FavoriteExercisesResult {
  const _FavoriteExercisesResult({
    this.favoriteExerciseName,
    this.usages = const <FavoriteExerciseUsage>[],
  });

  final String? favoriteExerciseName;
  final List<FavoriteExerciseUsage> usages;
}
