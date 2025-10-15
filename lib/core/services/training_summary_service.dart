import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
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
    this.snapshot,
  });

  final String dateKey;
  final DateTime date;
  final int logCount;
  final int totalSessions;
  final List<FavoriteExerciseUsage> favoriteExercises;
  final List<MuscleGroupUsage> muscleGroups;
  final Map<String, SessionCountInfo> sessionCounts;
  final Map<String, int> deviceCounts;
  final QueryDocumentSnapshot<Map<String, dynamic>>? snapshot;

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
    required this.deviceCounts,
  });

  final int trainingDayCount;
  final double averageTrainingDaysPerWeek;
  final List<FavoriteExerciseUsage> favoriteExercises;
  final List<MuscleGroupUsage> muscleGroups;
  final int totalSessions;
  final DateTime? firstWorkoutDate;
  final DateTime? lastWorkoutDate;
  final Map<String, int> deviceCounts;
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
    Duration ttl = const Duration(hours: 24),
    int pageSize = 30,
    void Function()? onRead,
    HiveInterface? hive,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _ttl = ttl,
        _pageSize = pageSize,
        _onRead = onRead,
        _hive = hive ?? Hive;

  final FirebaseFirestore _firestore;
  final Duration _ttl;
  final int _pageSize;
  final void Function()? _onRead;
  final HiveInterface _hive;
  final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};
  final Map<String, _GroupCacheEntry> _groupCache = <String, _GroupCacheEntry>{};
  final Map<String, Future<Box<dynamic>>> _boxCache = <String, Future<Box<dynamic>>>{};

  Future<TrainingSummaryState> loadSummaries({
    required String userId,
    bool forceRefresh = false,
    bool loadMore = false,
  }) async {
    final cache = _cache.putIfAbsent(userId, () => _CacheEntry.empty());
    if (forceRefresh) {
      await _clearPersistedDaily(userId);
      await _clearPersistedAggregate(userId);
      cache.clear();
    }

    if (!loadMore && cache.entries.isNotEmpty && !_isExpired(cache.fetchedAt)) {
      final aggregate = await _ensureAggregate(userId, cache);
      return TrainingSummaryState(
        entries: List<TrainingSummary>.from(cache.entries),
        aggregate: aggregate,
        hasMore: cache.hasMore,
        fromCache: true,
      );
    }

    if (!loadMore) {
      final persisted = await _readPersistedDaily(userId);
      if (persisted != null && !_isExpired(persisted.fetchedAt)) {
        cache.entries
          ..clear()
          ..addAll(persisted.entries);
        cache.hasMore = persisted.hasMore;
        cache.fetchedAt = persisted.fetchedAt;
        cache.lastDocument = null;
        cache.lastDocumentId = persisted.lastDocumentId;
        cache.lastDocumentDate = persisted.lastDocumentDate;
        final aggregate = await _ensureAggregate(userId, cache);
        return TrainingSummaryState(
          entries: List<TrainingSummary>.from(cache.entries),
          aggregate: aggregate,
          hasMore: cache.hasMore,
          fromCache: true,
        );
      }
    }

    if (loadMore && cache.entries.isEmpty) {
      // There is nothing to extend; fall back to a normal load.
      loadMore = false;
    }

    if (loadMore && _isExpired(cache.fetchedAt)) {
      cache.clear();
      loadMore = false;
    }

    if (loadMore && cache.lastDocument == null && cache.lastDocumentId != null) {
      final doc = await _firestore
          .collection('trainingSummary')
          .doc(userId)
          .collection('daily')
          .doc(cache.lastDocumentId!)
          .get();
      if (doc.exists) {
        cache.lastDocument = doc;
      }
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
    cache.lastDocumentId = cache.lastDocument?.id ?? cache.lastDocumentId;
    cache.lastDocumentDate = snapshot.docs.isNotEmpty
        ? _timestampToDate(snapshot.docs.last.data()['date']) ?? cache.lastDocumentDate
        : cache.lastDocumentDate;
    cache.fetchedAt = DateTime.now();
    cache.hasMore = snapshot.docs.length >= _pageSize;

    final aggregate = await _ensureAggregate(
      userId,
      cache,
      refresh: forceRefresh || cache.aggregate == null,
    );

    if (!loadMore) {
      await _writePersistedDaily(
        userId,
        cache.entries,
        cache.hasMore,
        cache.fetchedAt!,
        cache.lastDocumentId,
        cache.lastDocumentDate,
      );
    }

    return TrainingSummaryState(
      entries: List<TrainingSummary>.from(cache.entries),
      aggregate: aggregate,
      hasMore: cache.hasMore,
      fromCache: false,
    );
  }

  Future<void> clearCache(String userId) async {
    _cache.remove(userId);
    await _clearPersistedDaily(userId);
    await _clearPersistedAggregate(userId);
  }

  Future<Map<String, int>> fetchGroupUsageCounts({
    required String gymId,
    required String userId,
    bool forceRefresh = false,
  }) async {
    final cache = _cache.putIfAbsent(userId, () => _CacheEntry.empty());
    final aggregate = await _ensureAggregate(
      userId,
      cache,
      refresh: forceRefresh,
    );

    if (aggregate.deviceCounts.isEmpty) {
      return const <String, int>{};
    }

    final groupCache = _groupCache[gymId];
    if (!forceRefresh && groupCache != null && !_isExpired(groupCache.fetchedAt)) {
      return _mapDeviceCountsToGroups(
        aggregate.deviceCounts,
        groupCache.deviceIdsByGroup,
      );
    }

    final snap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('muscleGroups')
        .get();
    _onRead?.call();

    final deviceIdsByGroup = <String, List<String>>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final primary = _extractIdList(data['primaryDeviceIds']);
      final secondary = _extractIdList(data['secondaryDeviceIds']);
      deviceIdsByGroup[doc.id] = [...primary, ...secondary];
    }

    _groupCache[gymId] = _GroupCacheEntry(
      deviceIdsByGroup: deviceIdsByGroup,
      fetchedAt: DateTime.now(),
    );

    return _mapDeviceCountsToGroups(
      aggregate.deviceCounts,
      deviceIdsByGroup,
    );
  }

  Query<Map<String, dynamic>> _baseQuery(
    String userId,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
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

    if (!refresh) {
      final persisted = await _readPersistedAggregate(userId);
      if (persisted != null && !_isExpired(persisted.fetchedAt)) {
        cache.aggregate = persisted.aggregate;
        cache.aggregateFetchedAt = persisted.fetchedAt;
        return persisted.aggregate;
      }
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
    await _writePersistedAggregate(userId, aggregate, cache.aggregateFetchedAt!);
    return aggregate;
  }

  Map<String, int> _mapDeviceCountsToGroups(
    Map<String, int> deviceCounts,
    Map<String, List<String>> deviceIdsByGroup,
  ) {
    final result = <String, int>{};
    deviceIdsByGroup.forEach((groupId, deviceIds) {
      var sum = 0;
      for (final deviceId in deviceIds) {
        sum += deviceCounts[deviceId] ?? 0;
      }
      result[groupId] = sum;
    });
    return result;
  }

  List<String> _extractIdList(dynamic raw) {
    if (raw is Iterable) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return const <String>[];
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
        deviceCounts: <String, int>{},
      );
    }
    final favoriteExercises = _mapFavoriteExercises(data['favoriteExercises']);
    final muscleGroups = _mapMuscleGroups(data['muscleGroups']);
    final firstWorkoutDate = _timestampToDate(data['firstWorkoutDate']);
    final lastWorkoutDate = _timestampToDate(data['lastWorkoutDate']);
    final deviceCounts = _mapCountMap(data['deviceCounts']);
    return TrainingSummaryAggregate(
      trainingDayCount: (data['trainingDayCount'] as num?)?.toInt() ?? 0,
      averageTrainingDaysPerWeek: (data['averageTrainingDaysPerWeek'] as num?)?.toDouble() ?? 0,
      favoriteExercises: favoriteExercises,
      muscleGroups: muscleGroups,
      totalSessions: (data['totalSessions'] as num?)?.toInt() ?? 0,
      firstWorkoutDate: firstWorkoutDate,
      lastWorkoutDate: lastWorkoutDate,
      deviceCounts: deviceCounts,
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

  Future<Box<dynamic>> _openBox(String name) {
    return _boxCache.putIfAbsent(name, () => _hive.openBox<dynamic>(name));
  }

  Future<void> _writePersistedDaily(
    String userId,
    List<TrainingSummary> entries,
    bool hasMore,
    DateTime fetchedAt,
    String? lastDocumentId,
    DateTime? lastDocumentDate,
  ) async {
    final box = await _openBox(_dailyBoxName(userId));
    box.put(
      'state',
      <String, dynamic>{
        'fetchedAt': fetchedAt.toIso8601String(),
        'hasMore': hasMore,
        'lastDocumentId': lastDocumentId,
        'lastDocumentDate': lastDocumentDate?.toIso8601String(),
        'entries': entries.map(_serializeSummary).toList(growable: false),
      },
    );
  }

  Future<_PersistedDailyState?> _readPersistedDaily(String userId) async {
    final box = await _openBox(_dailyBoxName(userId));
    final raw = box.get('state');
    if (raw is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(raw as Map);
    final fetchedAtIso = map['fetchedAt'] as String?;
    if (fetchedAtIso == null) {
      return null;
    }
    final fetchedAt = DateTime.tryParse(fetchedAtIso);
    if (fetchedAt == null) {
      return null;
    }
    final entriesRaw = map['entries'];
    if (entriesRaw is! List) {
      return null;
    }
    final entries = entriesRaw
        .whereType<Map>()
        .map((entry) => _deserializeSummary(Map<String, dynamic>.from(entry)))
        .toList(growable: false);
    final hasMore = map['hasMore'] as bool? ?? false;
    final lastDocumentId = map['lastDocumentId'] as String?;
    final lastDocumentDateIso = map['lastDocumentDate'] as String?;
    final lastDocumentDate =
        lastDocumentDateIso != null ? DateTime.tryParse(lastDocumentDateIso) : null;
    return _PersistedDailyState(
      entries: entries,
      hasMore: hasMore,
      fetchedAt: fetchedAt,
      lastDocumentId: lastDocumentId,
      lastDocumentDate: lastDocumentDate,
    );
  }

  Future<void> _clearPersistedDaily(String userId) async {
    final box = await _openBox(_dailyBoxName(userId));
    await box.delete('state');
  }

  Future<void> _writePersistedAggregate(
    String userId,
    TrainingSummaryAggregate aggregate,
    DateTime fetchedAt,
  ) async {
    final box = await _openBox(_aggregateBoxName(userId));
    await box.put(
      'aggregate',
      <String, dynamic>{
        'fetchedAt': fetchedAt.toIso8601String(),
        'value': _serializeAggregate(aggregate),
      },
    );
  }

  Future<_PersistedAggregate?> _readPersistedAggregate(String userId) async {
    final box = await _openBox(_aggregateBoxName(userId));
    final raw = box.get('aggregate');
    if (raw is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(raw as Map);
    final fetchedAtIso = map['fetchedAt'] as String?;
    final fetchedAt = fetchedAtIso != null ? DateTime.tryParse(fetchedAtIso) : null;
    final value = map['value'];
    if (fetchedAt == null || value is! Map) {
      return null;
    }
    final aggregate =
        _deserializeAggregate(Map<String, dynamic>.from(value as Map));
    return _PersistedAggregate(aggregate: aggregate, fetchedAt: fetchedAt);
  }

  Future<void> _clearPersistedAggregate(String userId) async {
    final box = await _openBox(_aggregateBoxName(userId));
    await box.delete('aggregate');
  }

  Map<String, dynamic> _serializeSummary(TrainingSummary summary) {
    return <String, dynamic>{
      'dateKey': summary.dateKey,
      'date': summary.date.toIso8601String(),
      'logCount': summary.logCount,
      'totalSessions': summary.totalSessions,
      'favoriteExercises': summary.favoriteExercises
          .map((usage) => <String, dynamic>{
                'name': usage.name,
                'sessionCount': usage.sessionCount,
              })
          .toList(growable: false),
      'muscleGroups': summary.muscleGroups
          .map((usage) => <String, dynamic>{
                'name': usage.name,
                'sessionCount': usage.sessionCount,
              })
          .toList(growable: false),
      'sessionCounts': summary.sessionCounts.map((key, value) => MapEntry(
            key,
            <String, dynamic>{
              'count': value.count,
              'gymId': value.gymId,
              'deviceId': value.deviceId,
            },
          )),
      'deviceCounts': Map<String, int>.from(summary.deviceCounts),
    };
  }

  TrainingSummary _deserializeSummary(Map<String, dynamic> raw) {
    final dateIso = raw['date'] as String?;
    final date = dateIso != null ? DateTime.tryParse(dateIso) ?? DateTime.now() : DateTime.now();
    final sessionCountsRaw = raw['sessionCounts'];
    return TrainingSummary(
      dateKey: raw['dateKey'] as String? ?? '',
      date: date,
      logCount: (raw['logCount'] as num?)?.toInt() ?? 0,
      totalSessions: (raw['totalSessions'] as num?)?.toInt() ?? 0,
      favoriteExercises:
          _deserializeFavoriteExercises(raw['favoriteExercises']) ?? const <FavoriteExerciseUsage>[],
      muscleGroups: _deserializeMuscleGroups(raw['muscleGroups']) ?? const <MuscleGroupUsage>[],
      sessionCounts: _deserializeSessionCounts(sessionCountsRaw),
      deviceCounts: _deserializeDeviceCounts(raw['deviceCounts']),
    );
  }

  Map<String, SessionCountInfo> _deserializeSessionCounts(dynamic raw) {
    if (raw is! Map) {
      return <String, SessionCountInfo>{};
    }
    final result = <String, SessionCountInfo>{};
    raw.forEach((key, value) {
      if (value is Map) {
        final data = Map<String, dynamic>.from(value as Map);
        result[key as String] = SessionCountInfo(
          count: (data['count'] as num?)?.toInt() ?? 0,
          gymId: data['gymId'] as String?,
          deviceId: data['deviceId'] as String?,
        );
      }
    });
    return result;
  }

  Map<String, int> _deserializeDeviceCounts(dynamic raw) {
    if (raw is! Map) {
      return <String, int>{};
    }
    final map = Map<String, dynamic>.from(raw as Map);
    return map.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));
  }

  List<FavoriteExerciseUsage>? _deserializeFavoriteExercises(dynamic raw) {
    if (raw is! List) {
      return null;
    }
    return raw
        .whereType<Map>()
        .map((entry) {
          final data = Map<String, dynamic>.from(entry);
          return FavoriteExerciseUsage(
            name: (data['name'] as String?) ?? '—',
            sessionCount: (data['sessionCount'] as num?)?.toInt() ?? 0,
          );
        })
        .toList(growable: false);
  }

  List<MuscleGroupUsage>? _deserializeMuscleGroups(dynamic raw) {
    if (raw is! List) {
      return null;
    }
    return raw
        .whereType<Map>()
        .map((entry) {
          final data = Map<String, dynamic>.from(entry);
          return MuscleGroupUsage(
            name: (data['name'] as String?) ?? '—',
            sessionCount: (data['sessionCount'] as num?)?.toInt() ?? 0,
          );
        })
        .toList(growable: false);
  }

  Map<String, dynamic> _serializeAggregate(TrainingSummaryAggregate aggregate) {
    return <String, dynamic>{
      'trainingDayCount': aggregate.trainingDayCount,
      'averageTrainingDaysPerWeek': aggregate.averageTrainingDaysPerWeek,
      'favoriteExercises': aggregate.favoriteExercises
          .map((usage) => <String, dynamic>{
                'name': usage.name,
                'sessionCount': usage.sessionCount,
              })
          .toList(growable: false),
      'muscleGroups': aggregate.muscleGroups
          .map((usage) => <String, dynamic>{
                'name': usage.name,
                'sessionCount': usage.sessionCount,
              })
          .toList(growable: false),
      'totalSessions': aggregate.totalSessions,
      'firstWorkoutDate': aggregate.firstWorkoutDate?.toIso8601String(),
      'lastWorkoutDate': aggregate.lastWorkoutDate?.toIso8601String(),
      'deviceCounts': Map<String, int>.from(aggregate.deviceCounts),
    };
  }

  TrainingSummaryAggregate _deserializeAggregate(Map<String, dynamic> raw) {
    final favoriteExercises = _deserializeFavoriteExercises(raw['favoriteExercises']) ??
        const <FavoriteExerciseUsage>[];
    final muscleGroups =
        _deserializeMuscleGroups(raw['muscleGroups']) ?? const <MuscleGroupUsage>[];
    final firstWorkoutIso = raw['firstWorkoutDate'] as String?;
    final lastWorkoutIso = raw['lastWorkoutDate'] as String?;
    return TrainingSummaryAggregate(
      trainingDayCount: (raw['trainingDayCount'] as num?)?.toInt() ?? 0,
      averageTrainingDaysPerWeek: (raw['averageTrainingDaysPerWeek'] as num?)?.toDouble() ?? 0,
      favoriteExercises: favoriteExercises,
      muscleGroups: muscleGroups,
      totalSessions: (raw['totalSessions'] as num?)?.toInt() ?? 0,
      firstWorkoutDate:
          firstWorkoutIso != null ? DateTime.tryParse(firstWorkoutIso) : null,
      lastWorkoutDate: lastWorkoutIso != null ? DateTime.tryParse(lastWorkoutIso) : null,
      deviceCounts: _deserializeDeviceCounts(raw['deviceCounts']),
    );
  }

  String _dailyBoxName(String userId) => 'summary_daily_${_sanitizeId(userId)}';

  String _aggregateBoxName(String userId) => 'summary_agg_${_sanitizeId(userId)}';

  String _sanitizeId(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
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
    this.lastDocumentId,
    this.lastDocumentDate,
  });

  final List<TrainingSummary> entries;
  DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  TrainingSummaryAggregate? aggregate;
  DateTime? aggregateFetchedAt;
  bool hasMore;
  DateTime? fetchedAt;
  String? lastDocumentId;
  DateTime? lastDocumentDate;

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
    lastDocumentId = null;
    lastDocumentDate = null;
  }
}

class _GroupCacheEntry {
  _GroupCacheEntry({
    required this.deviceIdsByGroup,
    required this.fetchedAt,
  });

  final Map<String, List<String>> deviceIdsByGroup;
  final DateTime fetchedAt;
}

class _PersistedDailyState {
  const _PersistedDailyState({
    required this.entries,
    required this.hasMore,
    required this.fetchedAt,
    required this.lastDocumentId,
    required this.lastDocumentDate,
  });

  final List<TrainingSummary> entries;
  final bool hasMore;
  final DateTime fetchedAt;
  final String? lastDocumentId;
  final DateTime? lastDocumentDate;
}

class _PersistedAggregate {
  const _PersistedAggregate({
    required this.aggregate,
    required this.fetchedAt,
  });

  final TrainingSummaryAggregate aggregate;
  final DateTime fetchedAt;
}
