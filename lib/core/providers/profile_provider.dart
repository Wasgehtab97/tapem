// lib/core/providers/profile_provider.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/models/favorite_exercise_usage.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/storage/profile_cache_store.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({
    FirebaseFirestore? firestore,
    ProfileCacheStore? cache,
    DateTime Function()? nowProvider,
    Duration? cacheTtl,
    Duration? favoriteExercisesLookback,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cache = cache ?? const ProfileCacheStore(),
        _nowProvider = nowProvider ?? DateTime.now,
        _cacheTtl = cacheTtl ?? const Duration(hours: 24),
        _favoriteExercisesLookback =
            favoriteExercisesLookback ?? const Duration(days: 180);

  final FirebaseFirestore _firestore;
  final ProfileCacheStore _cache;
  final DateTime Function() _nowProvider;
  final Duration _cacheTtl;
  final Duration _favoriteExercisesLookback;

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
  bool _isFavoriteExercisesLoading = false;
  bool _hasLoadedFavoriteExercises = false;
  String? _favoriteExercisesError;
  String? _pendingFavoriteExercisesUserId;
  Future<void>? _inFlightFavoriteExercisesLoad;
  DateTime? _lastCacheAt;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _trainingDaySubscription;
  String? _trainingDaySubscriptionUserId;
  DateTime? _lastKnownCreatedAt;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get trainingDates => List.unmodifiable(_trainingDates);
  List<DateTime> get trainingDayDates => List.unmodifiable(_trainingDayDates);
  int get totalTrainingDays => _totalTrainingDays;
  double get averageTrainingDaysPerWeek => _avgTrainingDaysPerWeek;
  String? get favoriteExerciseName => _favoriteExerciseName;
  List<FavoriteExerciseUsage> get favoriteExerciseUsages =>
      List.unmodifiable(_favoriteExerciseUsages);
  bool get isFavoriteExercisesLoading => _isFavoriteExercisesLoading;
  String? get favoriteExercisesError => _favoriteExercisesError;
  bool get hasLoadedFavoriteExercises => _hasLoadedFavoriteExercises;

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

    _lastKnownCreatedAt = authProv.createdAt;

    if (!forceRefresh &&
        _hasLoadedTrainingDates &&
        _lastLoadedUserId == userId) {
      final now = _nowProvider();
      final lastCache = _lastCacheAt;
      final hasFreshData = lastCache != null &&
          now.difference(lastCache) <= _cacheTtl &&
          _isSameCalendarDay(now, lastCache);
      if (hasFreshData) {
        return;
      }
    }

    if (_inFlightTrainingLoad != null &&
        _pendingTrainingUserId == userId) {
      await _inFlightTrainingLoad;
      return;
    }

    final hasFreshCache = await _tryLoadFromCache(userId, forceRefresh);
    if (hasFreshCache) {
      _ensureTrainingDaySubscription(userId);
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final future = _loadFromFirestore(
      userId: userId,
      createdAt: authProv.createdAt,
    );
    _pendingTrainingUserId = userId;
    _inFlightTrainingLoad = future.whenComplete(() {
      _pendingTrainingUserId = null;
      _inFlightTrainingLoad = null;
    });
    await _inFlightTrainingLoad;
    _ensureTrainingDaySubscription(userId);
  }

  Future<bool> _tryLoadFromCache(String userId, bool forceRefresh) async {
    if (forceRefresh) {
      return false;
    }

    final cached = await _cache.read(userId);
    if (cached == null) {
      return false;
    }

    final now = _nowProvider();
    final shouldInvalidate =
        cached.isExpired(now, _cacheTtl) || !_isSameCalendarDay(now, cached.cachedAt);

    _assignEntry(cached, userId);
    _error = null;
    _isLoading = shouldInvalidate;
    notifyListeners();
    return !shouldInvalidate;
  }

  Future<void> _loadFromFirestore({
    required String userId,
    required DateTime? createdAt,
  }) async {
    try {
      final entry = await _fetchTrainingOverview(
        userId: userId,
        createdAt: createdAt,
        now: _nowProvider(),
      );
      _assignEntry(entry, userId);
      _error = null;
      await _cache.write(userId, _buildCacheEntry(entry.cachedAt));
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

  Future<ProfileCacheEntry> _fetchTrainingOverview({
    required String userId,
    required DateTime? createdAt,
    required DateTime now,
  }) async {
    final collection = _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingDayXP')
        .orderBy(FieldPath.documentId);

    final snapshot = await collection.get();

    final trainingDayDates = <DateTime>[];
    for (final doc in snapshot.docs) {
      final parsed = DateTime.tryParse(doc.id);
      if (parsed != null) {
        trainingDayDates.add(DateTime(parsed.year, parsed.month, parsed.day));
      }
    }
    trainingDayDates.sort((a, b) => a.compareTo(b));
    final trainingDates = trainingDayDates
        .map((dt) =>
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}')
        .toList();
    final totalTrainingDays = trainingDates.length;
    final avgTrainingDaysPerWeek = _calculateAverageTrainingDaysPerWeek(
      trainingDayDates,
      createdAt,
      nowProvider: () => now,
    );

    final keepFavorites =
        _lastLoadedUserId == userId && _hasLoadedFavoriteExercises;

    return ProfileCacheEntry(
      trainingDates: trainingDates,
      trainingDayDates: trainingDayDates,
      totalTrainingDays: totalTrainingDays,
      averageTrainingDaysPerWeek: avgTrainingDaysPerWeek,
      favoriteExerciseName: keepFavorites ? _favoriteExerciseName : null,
      favoriteExerciseUsages: keepFavorites
          ? List<FavoriteExerciseUsage>.from(_favoriteExerciseUsages)
          : const <FavoriteExerciseUsage>[],
      cachedAt: now,
    );
  }

  void _assignEntry(ProfileCacheEntry entry, String userId) {
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
    _hasLoadedFavoriteExercises =
        _favoriteExerciseName != null || _favoriteExerciseUsages.isNotEmpty;
    _favoriteExercisesError = null;
    _lastCacheAt = entry.cachedAt;
  }

  ProfileCacheEntry _buildCacheEntry(DateTime now) {
    return ProfileCacheEntry(
      trainingDates: List<String>.from(_trainingDates),
      trainingDayDates: List<DateTime>.from(_trainingDayDates),
      totalTrainingDays: _totalTrainingDays,
      averageTrainingDaysPerWeek: _avgTrainingDaysPerWeek,
      favoriteExerciseName: _favoriteExerciseName,
      favoriteExerciseUsages:
          List<FavoriteExerciseUsage>.from(_favoriteExerciseUsages),
      cachedAt: now,
    );
  }

  void _ensureTrainingDaySubscription(String userId) {
    if (_trainingDaySubscriptionUserId == userId &&
        _trainingDaySubscription != null) {
      return;
    }

    _trainingDaySubscription?.cancel();
    _trainingDaySubscriptionUserId = userId;

    final query = _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingDayXP')
        .orderBy(FieldPath.documentId);

    _trainingDaySubscription = query.snapshots().listen(
      (snapshot) {
        if (_disposed) return;

        final trainingDayDates = <DateTime>[];
        for (final doc in snapshot.docs) {
          final parsed = DateTime.tryParse(doc.id);
          if (parsed != null) {
            trainingDayDates
                .add(DateTime(parsed.year, parsed.month, parsed.day));
          }
        }
        trainingDayDates.sort((a, b) => a.compareTo(b));

        final trainingDates = trainingDayDates
            .map((dt) =>
                '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}')
            .toList();

        if (const ListEquality<String>().equals(
          _trainingDates,
          trainingDates,
        )) {
          return;
        }

        _trainingDates = trainingDates;
        _trainingDayDates = trainingDayDates;
        _totalTrainingDays = trainingDates.length;
        _avgTrainingDaysPerWeek = _calculateAverageTrainingDaysPerWeek(
          trainingDayDates,
          _lastKnownCreatedAt,
          nowProvider: _nowProvider,
        );
        _hasLoadedTrainingDates = true;
        _lastLoadedUserId = userId;
        _lastCacheAt = _nowProvider();

        final cacheEntry = _buildCacheEntry(_lastCacheAt!);
        unawaited(_cache.write(userId, cacheEntry));
        notifyListeners();
      },
      onError: (Object error, StackTrace st) {
        elogError('PROFILE_TRAINING_DATES_STREAM_FAILED', error, st, {
          'uid': userId,
        });
      },
    );
  }

  bool _isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> ensureFavoriteExercisesLoaded(
    BuildContext context, {
    bool forceRefresh = false,
  }) async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProv.userId;

    if (userId == null) {
      _favoriteExercisesError = 'Kein Benutzer gefunden';
      notifyListeners();
      return;
    }

    if (!forceRefresh && _hasLoadedFavoriteExercises &&
        _lastLoadedUserId == userId) {
      return;
    }

    if (_inFlightFavoriteExercisesLoad != null &&
        _pendingFavoriteExercisesUserId == userId) {
      await _inFlightFavoriteExercisesLoad;
      return;
    }

    _isFavoriteExercisesLoading = true;
    _favoriteExercisesError = null;
    notifyListeners();

    final future = _loadFavoriteExercisesFromFirestore(
      userId: userId,
      createdAt: authProv.createdAt,
    );
    _pendingFavoriteExercisesUserId = userId;
    _inFlightFavoriteExercisesLoad = future.whenComplete(() {
      _pendingFavoriteExercisesUserId = null;
      _inFlightFavoriteExercisesLoad = null;
    });
    await _inFlightFavoriteExercisesLoad;
  }

  Future<void> _loadFavoriteExercisesFromFirestore({
    required String userId,
    required DateTime? createdAt,
  }) async {
    try {
      final now = _nowProvider();
      var since = now.subtract(_favoriteExercisesLookback);
      if (createdAt != null && createdAt.isAfter(since)) {
        since = createdAt;
      }
      final normalizedSince = DateTime(since.year, since.month, since.day);

      final snapshot = await _firestore
          .collectionGroup('logs')
          .where('userId', isEqualTo: userId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(normalizedSince.toUtc()),
          )
          .get();

      final sessionAggregates = <String, _ExerciseAggregate>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
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

      final favoriteExercises = await _resolveFavoriteExercises(
        sessionAggregates.values,
      );

      _favoriteExerciseName = favoriteExercises.favoriteExerciseName;
      _favoriteExerciseUsages = favoriteExercises.usages;
      _hasLoadedFavoriteExercises = true;
      _favoriteExercisesError = null;
      _isFavoriteExercisesLoading = false;
      await _cache.write(userId, _buildCacheEntry(now));
      notifyListeners();
    } catch (e, st) {
      _favoriteExercisesError =
          'Fehler beim Laden der Lieblingsübungen: ${e.toString()}';
      _isFavoriteExercisesLoading = false;
      if (e is FirebaseException && e.code == 'failed-precondition') {
        elogError('FIRESTORE_FAILED_PRECONDITION', e.message ?? e.toString(), st);
      }
      debugPrintStack(
        label: 'ProfileProvider.ensureFavoriteExercisesLoaded',
        stackTrace: st,
      );
      notifyListeners();
    }
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

  @override
  void dispose() {
    _disposed = true;
    _trainingDaySubscription?.cancel();
    super.dispose();
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
