import 'package:cloud_firestore/cloud_firestore.dart';

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
    Duration ttl = const Duration(minutes: 5),
    void Function()? onRead,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _ttl = ttl,
        _onRead = onRead;

  final FirebaseFirestore _firestore;
  final Duration _ttl;
  final void Function()? _onRead;
  final Map<String, _DeviceSummaryCache> _cache =
      <String, _DeviceSummaryCache>{};

  Future<DeviceUsageSummaryState> loadSummaries(
    String gymId, {
    bool forceRefresh = false,
  }) async {
    final cache = _cache.putIfAbsent(
      gymId,
      () => _DeviceSummaryCache.empty(),
    );

    if (!forceRefresh && !_isExpired(cache.fetchedAt) &&
        cache.entries.isNotEmpty) {
      return DeviceUsageSummaryState(
        entries: List<DeviceUsageSummaryEntry>.from(cache.entries),
        fromCache: true,
      );
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
}
