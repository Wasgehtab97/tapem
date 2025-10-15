import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/core/models/favorite_exercise_usage.dart';

class TrainingSummary {
  TrainingSummary({
    required this.dateKey,
    required this.date,
    required this.logCount,
    required this.totalSessions,
    required this.favoriteExercises,
    required this.muscleGroups,
    required this.sessionCounts,
    required this.deviceCounts,
    required this.snapshot,
  });

  final String dateKey;
  final DateTime date;
  final int logCount;
  final int totalSessions;
  final List<FavoriteExerciseUsage> favoriteExercises;
  final List<MuscleGroupUsage> muscleGroups;
  final Map<String, SessionCountInfo> sessionCounts;
  final Map<String, int> deviceCounts;
  final QueryDocumentSnapshot<Map<String, dynamic>> snapshot;

  Set<String> get sessionIds => sessionCounts.entries
      .where((entry) => entry.value.count > 0)
      .map((entry) => entry.key)
      .toSet();
}

class SessionCountInfo {
  const SessionCountInfo({
    required this.count,
    this.gymId,
    this.deviceId,
  });

  final int count;
  final String? gymId;
  final String? deviceId;
}

class MuscleGroupUsage {
  const MuscleGroupUsage({
    required this.name,
    required this.sessionCount,
  });

  final String name;
  final int sessionCount;
}

class TrainingSummaryAggregate {
  const TrainingSummaryAggregate({
    required this.trainingDayCount,
    required this.averageTrainingDaysPerWeek,
    required this.favoriteExercises,
    required this.muscleGroups,
    required this.totalSessions,
    required this.firstWorkoutDate,
    required this.lastWorkoutDate,
  });

  final int trainingDayCount;
  final double averageTrainingDaysPerWeek;
  final List<FavoriteExerciseUsage> favoriteExercises;
  final List<MuscleGroupUsage> muscleGroups;
  final int totalSessions;
  final DateTime? firstWorkoutDate;
  final DateTime? lastWorkoutDate;
}

class TrainingSummaryState {
  const TrainingSummaryState({
    required this.entries,
    required this.aggregate,
    required this.hasMore,
    required this.fromCache,
  });

  final List<TrainingSummary> entries;
  final TrainingSummaryAggregate aggregate;
  final bool hasMore;
  final bool fromCache;
}

class TrainingSummaryService {
  TrainingSummaryService({
    FirebaseFirestore? firestore,
    Duration ttl = const Duration(minutes: 10),
    int pageSize = 30,
    void Function()? onRead,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _ttl = ttl,
        _pageSize = pageSize,
        _onRead = onRead;

  final FirebaseFirestore _firestore;
  final Duration _ttl;
  final int _pageSize;
  final void Function()? _onRead;
  final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};

  Future<TrainingSummaryState> loadSummaries({
    required String userId,
    bool forceRefresh = false,
    bool loadMore = false,
  }) async {
    final cache = _cache.putIfAbsent(userId, () => _CacheEntry.empty());
    if (forceRefresh) {
      cache.clear();
    }
    if (!loadMore && !_isExpired(cache.fetchedAt) && cache.entries.isNotEmpty) {
      final aggregate = await _ensureAggregate(userId, cache);
      return TrainingSummaryState(
        entries: List<TrainingSummary>.from(cache.entries),
        aggregate: aggregate,
        hasMore: cache.hasMore,
        fromCache: true,
      );
    }

    if (loadMore && cache.entries.isEmpty) {
      // There is nothing to extend; fall back to a normal load.
      loadMore = false;
    }

    if (loadMore && _isExpired(cache.fetchedAt)) {
      cache.clear();
      loadMore = false;
    }

    final query = _baseQuery(userId, cache.lastDocument, loadMore);
    final snapshot = await query.get();
    _onRead?.call();

    final newEntries = snapshot.docs.map(_mapSummary).toList();

    if (loadMore) {
      cache.entries.addAll(newEntries);
    } else {
      cache.entries
        ..clear()
        ..addAll(newEntries);
    }
    cache.lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : cache.lastDocument;
    cache.fetchedAt = DateTime.now();
    cache.hasMore = snapshot.docs.length >= _pageSize;

    final aggregate = await _ensureAggregate(userId, cache, refresh: forceRefresh || cache.aggregate == null);

    return TrainingSummaryState(
      entries: List<TrainingSummary>.from(cache.entries),
      aggregate: aggregate,
      hasMore: cache.hasMore,
      fromCache: false,
    );
  }

  void clearCache(String userId) {
    _cache.remove(userId);
  }

  Query<Map<String, dynamic>> _baseQuery(
    String userId,
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool loadMore,
  ) {
    var query = _firestore
        .collection('trainingSummary')
        .doc(userId)
        .collection('daily')
        .orderBy('date', descending: true)
        .limit(_pageSize);
    if (loadMore && lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    return query;
  }

  Future<TrainingSummaryAggregate> _ensureAggregate(
    String userId,
    _CacheEntry cache, {
    bool refresh = false,
  }) async {
    if (!refresh && cache.aggregate != null && !_isExpired(cache.aggregateFetchedAt)) {
      return cache.aggregate!;
    }
    final doc = await _firestore
        .collection('trainingSummary')
        .doc(userId)
        .collection('aggregate')
        .doc('overview')
        .get();
    _onRead?.call();
    final aggregate = _mapAggregate(doc);
    cache.aggregate = aggregate;
    cache.aggregateFetchedAt = DateTime.now();
    return aggregate;
  }

  bool _isExpired(DateTime? timestamp) {
    if (timestamp == null) {
      return true;
    }
    return DateTime.now().difference(timestamp) > _ttl;
  }

  TrainingSummary _mapSummary(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final timestamp = data['date'];
    final date = timestamp is Timestamp ? timestamp.toDate() : DateTime.now();
    final favoriteExercises = _mapFavoriteExercises(data['favoriteExercises']);
    final muscleGroups = _mapMuscleGroups(data['muscleGroups']);
    final sessionCounts = _mapSessionCounts(data['sessionCounts']);
    final deviceCounts = _mapCountMap(data['deviceCounts']);
    return TrainingSummary(
      dateKey: data['dateKey'] as String? ?? doc.id,
      date: date,
      logCount: (data['logCount'] as num?)?.toInt() ?? 0,
      totalSessions: (data['totalSessions'] as num?)?.toInt() ?? 0,
      favoriteExercises: favoriteExercises,
      muscleGroups: muscleGroups,
      sessionCounts: sessionCounts,
      deviceCounts: deviceCounts,
      snapshot: doc,
    );
  }

  TrainingSummaryAggregate _mapAggregate(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      return const TrainingSummaryAggregate(
        trainingDayCount: 0,
        averageTrainingDaysPerWeek: 0,
        favoriteExercises: <FavoriteExerciseUsage>[],
        muscleGroups: <MuscleGroupUsage>[],
        totalSessions: 0,
        firstWorkoutDate: null,
        lastWorkoutDate: null,
      );
    }
    final favoriteExercises = _mapFavoriteExercises(data['favoriteExercises']);
    final muscleGroups = _mapMuscleGroups(data['muscleGroups']);
    final firstWorkoutDate = _timestampToDate(data['firstWorkoutDate']);
    final lastWorkoutDate = _timestampToDate(data['lastWorkoutDate']);
    return TrainingSummaryAggregate(
      trainingDayCount: (data['trainingDayCount'] as num?)?.toInt() ?? 0,
      averageTrainingDaysPerWeek: (data['averageTrainingDaysPerWeek'] as num?)?.toDouble() ?? 0,
      favoriteExercises: favoriteExercises,
      muscleGroups: muscleGroups,
      totalSessions: (data['totalSessions'] as num?)?.toInt() ?? 0,
      firstWorkoutDate: firstWorkoutDate,
      lastWorkoutDate: lastWorkoutDate,
    );
  }

  List<FavoriteExerciseUsage> _mapFavoriteExercises(dynamic raw) {
    if (raw is! Iterable) {
      return const <FavoriteExerciseUsage>[];
    }
    return raw
        .map((entry) => entry is Map<String, dynamic>
            ? FavoriteExerciseUsage(
                name: (entry['name'] as String?)?.trim().isNotEmpty == true
                    ? (entry['name'] as String).trim()
                    : (entry['id'] as String?) ?? '—',
                sessionCount: (entry['count'] as num?)?.toInt() ?? 0,
              )
            : null)
        .whereType<FavoriteExerciseUsage>()
        .toList(growable: false);
  }

  List<MuscleGroupUsage> _mapMuscleGroups(dynamic raw) {
    if (raw is! Iterable) {
      return const <MuscleGroupUsage>[];
    }
    return raw
        .map((entry) => entry is Map<String, dynamic>
            ? MuscleGroupUsage(
                name: (entry['name'] as String?)?.trim().isNotEmpty == true
                    ? (entry['name'] as String).trim()
                    : (entry['id'] as String?) ?? '—',
                sessionCount: (entry['count'] as num?)?.toInt() ?? 0,
              )
            : null)
        .whereType<MuscleGroupUsage>()
        .toList(growable: false);
  }

  Map<String, int> _mapCountMap(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return <String, int>{};
    }
    return raw.map((key, value) {
      if (value is Map<String, dynamic>) {
        return MapEntry(key, (value['count'] as num?)?.toInt() ?? 0);
      }
      return MapEntry(key, (value as num?)?.toInt() ?? 0);
    });
  }

  Map<String, SessionCountInfo> _mapSessionCounts(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return <String, SessionCountInfo>{};
    }
    final result = <String, SessionCountInfo>{};
    raw.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key] = SessionCountInfo(
          count: (value['count'] as num?)?.toInt() ?? 0,
          gymId: (value['gymId'] as String?)?.trim(),
          deviceId: (value['deviceId'] as String?)?.trim(),
        );
      } else {
        result[key] = SessionCountInfo(
          count: (value as num?)?.toInt() ?? 0,
        );
      }
    });
    return result;
  }

  DateTime? _timestampToDate(dynamic raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    if (raw is Map<String, dynamic> && raw['_seconds'] != null) {
      final seconds = raw['_seconds'];
      if (seconds is num) {
        return DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000);
      }
    }
    return null;
  }
}

class _CacheEntry {
  _CacheEntry({
    required this.entries,
    this.lastDocument,
    this.aggregate,
    this.aggregateFetchedAt,
    this.hasMore = true,
    this.fetchedAt,
  });

  final List<TrainingSummary> entries;
  QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
  TrainingSummaryAggregate? aggregate;
  DateTime? aggregateFetchedAt;
  bool hasMore;
  DateTime? fetchedAt;

  factory _CacheEntry.empty() {
    return _CacheEntry(entries: <TrainingSummary>[]);
  }

  void clear() {
    entries.clear();
    lastDocument = null;
    aggregate = null;
    aggregateFetchedAt = null;
    hasMore = true;
    fetchedAt = null;
  }
}
