import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

const String _rangeKey7Days = 'last7Days';
const String _rangeKey30Days = 'last30Days';
const String _rangeKey90Days = 'last90Days';
const String _rangeKey365Days = 'last365Days';
const String _rangeKeyAll = 'all';

class DeviceUsageSummaryEntry {
  DeviceUsageSummaryEntry({
    required this.deviceId,
    required this.name,
    required this.description,
    required this.totalSessions,
    required this.rangeCounts,
    required this.lastActive,
    required this.recentDates,
  });

  final String deviceId;
  final String name;
  final String description;
  final int totalSessions;
  final Map<String, int> rangeCounts;
  final DateTime? lastActive;
  final List<DateTime> recentDates;

  int countForRangeKey(String key) {
    return rangeCounts[key] ??
        (key == _rangeKeyAll ? totalSessions : 0);
  }
}

class DeviceUsageSummaryState {
  DeviceUsageSummaryState({
    required this.entries,
    required this.fromCache,
  });

  final List<DeviceUsageSummaryEntry> entries;
  final bool fromCache;
}

class DeviceUsageSummaryService {
  DeviceUsageSummaryService({
    FirebaseFirestore? firestore,
    Duration ttl = const Duration(hours: 24),
    void Function()? onRead,
    HiveInterface? hive,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _ttl = ttl,
        _onRead = onRead,
        _hive = hive ?? Hive;

  final FirebaseFirestore _firestore;
  final Duration _ttl;
  final void Function()? _onRead;
  final Map<String, _DeviceSummaryCache> _cache =
      <String, _DeviceSummaryCache>{};
  final HiveInterface _hive;
  final Map<String, Future<Box<dynamic>>> _boxCache = <String, Future<Box<dynamic>>>{};

  Future<DeviceUsageSummaryState> loadSummaries(
    String gymId, {
    bool forceRefresh = false,
  }) async {
    final cache = _cache.putIfAbsent(
      gymId,
      () => _DeviceSummaryCache.empty(),
    );

    if (forceRefresh) {
      await _clearPersisted(gymId);
      cache.clear();
    }

    if (!forceRefresh && cache.entries.isNotEmpty && !_isExpired(cache.fetchedAt)) {
      return DeviceUsageSummaryState(
        entries: List<DeviceUsageSummaryEntry>.from(cache.entries),
        fromCache: true,
      );
    }

    if (!forceRefresh) {
      final persisted = await _readPersisted(gymId);
      if (persisted != null && !_isExpired(persisted.fetchedAt)) {
        cache.entries
          ..clear()
          ..addAll(persisted.entries);
        cache.fetchedAt = persisted.fetchedAt;
        return DeviceUsageSummaryState(
          entries: List<DeviceUsageSummaryEntry>.from(cache.entries),
          fromCache: true,
        );
      }
    }

    final snapshot = await _firestore
        .collection('deviceUsageSummary')
        .doc(gymId)
        .collection('devices')
        .get();
    _onRead?.call();

    final entries = snapshot.docs.map(_mapEntry).toList();
    cache.entries
      ..clear()
      ..addAll(entries);
    cache.fetchedAt = DateTime.now();

    await _writePersisted(gymId, cache.entries, cache.fetchedAt!);

    return DeviceUsageSummaryState(
      entries: List<DeviceUsageSummaryEntry>.from(entries),
      fromCache: false,
    );
  }

  Future<List<DateTime>> fetchRecentActivityDates(
    String gymId, {
    bool forceRefresh = false,
  }) async {
    final state = await loadSummaries(
      gymId,
      forceRefresh: forceRefresh,
    );
    final uniqueDays = <DateTime>{};
    for (final entry in state.entries) {
      for (final date in entry.recentDates) {
        uniqueDays.add(DateTime(date.year, date.month, date.day));
      }
    }
    final result = uniqueDays.toList()
      ..sort((a, b) => a.compareTo(b));
    return result;
  }

  DeviceUsageSummaryEntry _mapEntry(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final name = (data['name'] as String?)?.trim();
    final description = (data['description'] as String?)?.trim();
    final totalSessions = (data['sessionCount'] as num?)?.toInt() ?? 0;
    final lastActive = _timestampToDate(data['lastActive']);
    final rangeCounts = _mapRangeCounts(data['rollingSessions'] ?? data['rangeCounts']);
    final recentDates = _mapRecentDates(data['recentDates']);
    return DeviceUsageSummaryEntry(
      deviceId: doc.id,
      name: name?.isNotEmpty == true ? name! : doc.id,
      description: description ?? '',
      totalSessions: totalSessions,
      rangeCounts: rangeCounts,
      lastActive: lastActive,
      recentDates: recentDates,
    );
  }

  Map<String, int> _mapRangeCounts(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return <String, int>{};
    }
    return <String, int>{
      _rangeKey7Days: (raw[_rangeKey7Days] as num?)?.toInt() ?? 0,
      _rangeKey30Days: (raw[_rangeKey30Days] as num?)?.toInt() ?? 0,
      _rangeKey90Days: (raw[_rangeKey90Days] as num?)?.toInt() ?? 0,
      _rangeKey365Days: (raw[_rangeKey365Days] as num?)?.toInt() ?? 0,
      _rangeKeyAll: (raw[_rangeKeyAll] as num?)?.toInt() ??
          (raw['total'] as num?)?.toInt() ?? 0,
    };
  }

  List<DateTime> _mapRecentDates(dynamic raw) {
    if (raw is! Iterable) {
      return const <DateTime>[];
    }
    return raw
        .map((value) => _timestampToDate(value))
        .whereType<DateTime>()
        .toList();
  }

  DateTime? _timestampToDate(dynamic raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    if (raw is Map<String, dynamic> && raw['_seconds'] is num) {
      final seconds = raw['_seconds'] as num;
      return DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000);
    }
    return null;
  }

  bool _isExpired(DateTime? timestamp) {
    if (timestamp == null) {
      return true;
    }
    return DateTime.now().difference(timestamp) > _ttl;
  }

  Future<Box<dynamic>> _openBox(String gymId) {
    final name = 'device_usage_${_sanitizeId(gymId)}';
    return _boxCache.putIfAbsent(name, () => _hive.openBox<dynamic>(name));
  }

  Future<void> _writePersisted(
    String gymId,
    List<DeviceUsageSummaryEntry> entries,
    DateTime fetchedAt,
  ) async {
    final box = await _openBox(gymId);
    await box.put(
      'state',
      <String, dynamic>{
        'fetchedAt': fetchedAt.toIso8601String(),
        'entries': entries.map(_serializeEntry).toList(growable: false),
      },
    );
  }

  Future<_PersistedDeviceState?> _readPersisted(String gymId) async {
    final box = await _openBox(gymId);
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
        .map((entry) => _deserializeEntry(Map<String, dynamic>.from(entry)))
        .toList(growable: false);
    return _PersistedDeviceState(entries: entries, fetchedAt: fetchedAt);
  }

  Future<void> _clearPersisted(String gymId) async {
    final box = await _openBox(gymId);
    await box.delete('state');
  }

  Map<String, dynamic> _serializeEntry(DeviceUsageSummaryEntry entry) {
    return <String, dynamic>{
      'deviceId': entry.deviceId,
      'name': entry.name,
      'description': entry.description,
      'totalSessions': entry.totalSessions,
      'rangeCounts': Map<String, int>.from(entry.rangeCounts),
      'lastActive': entry.lastActive?.toIso8601String(),
      'recentDates': entry.recentDates.map((date) => date.toIso8601String()).toList(),
    };
  }

  DeviceUsageSummaryEntry _deserializeEntry(Map<String, dynamic> raw) {
    final rangeCountsRaw = raw['rangeCounts'];
    final recentDatesRaw = raw['recentDates'];
    return DeviceUsageSummaryEntry(
      deviceId: raw['deviceId'] as String? ?? '',
      name: raw['name'] as String? ?? '',
      description: raw['description'] as String? ?? '',
      totalSessions: (raw['totalSessions'] as num?)?.toInt() ?? 0,
      rangeCounts: rangeCountsRaw is Map
          ? Map<String, int>.from(
              Map<String, dynamic>.from(rangeCountsRaw as Map).map(
                (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
              ),
            )
          : <String, int>{},
      lastActive: (raw['lastActive'] as String?) != null
          ? DateTime.tryParse(raw['lastActive'] as String)
          : null,
      recentDates: recentDatesRaw is List
          ? recentDatesRaw
              .map((value) => value is String ? DateTime.tryParse(value) : null)
              .whereType<DateTime>()
              .toList()
          : const <DateTime>[],
    );
  }

  String _sanitizeId(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}

class _DeviceSummaryCache {
  _DeviceSummaryCache({
    required this.entries,
    this.fetchedAt,
  });

  final List<DeviceUsageSummaryEntry> entries;
  DateTime? fetchedAt;

  factory _DeviceSummaryCache.empty() {
    return _DeviceSummaryCache(entries: <DeviceUsageSummaryEntry>[]);
  }

  void clear() {
    entries.clear();
    fetchedAt = null;
  }
}

class _PersistedDeviceState {
  const _PersistedDeviceState({
    required this.entries,
    required this.fetchedAt,
  });

  final List<DeviceUsageSummaryEntry> entries;
  final DateTime fetchedAt;
}
