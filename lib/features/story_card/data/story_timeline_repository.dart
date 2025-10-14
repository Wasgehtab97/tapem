import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/story_timeline_entry.dart';
import '../domain/story_timeline_filter.dart';

class StoryTimelinePage {
  StoryTimelinePage({
    required this.entries,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<StoryTimelineEntry> entries;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
}

class StoryTimelineRepository {
  StoryTimelineRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _stories(String userId) =>
      _firestore.collection('users').doc(userId).collection('stories');

  DocumentReference<Map<String, dynamic>> _metrics(String userId) =>
      _firestore.collection('users').doc(userId).collection('storyMetrics').doc('summary');

  Future<StoryTimelinePage> fetchStories({
    required String userId,
    required StoryTimelineFilter filter,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
    bool preferCache = false,
  }) async {
    if (userId.isEmpty) {
      return StoryTimelinePage(entries: const [], lastDocument: null, hasMore: false);
    }

    Query<Map<String, dynamic>> query = _stories(userId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    final now = DateTime.now();
    final rangeStart = _rangeStart(filter.range, now);
    if (rangeStart != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart));
    }

    switch (filter.prFilter) {
      case StoryTimelinePrFilter.prsOnly:
        query = query.where('prCount', isGreaterThan: 0);
        break;
      case StoryTimelinePrFilter.firsts:
        query = query.where('prTypes', arrayContainsAny: ['first_device', 'first_exercise']);
        break;
      case StoryTimelinePrFilter.strength:
        query = query.where('prTypes', arrayContains: 'e1rm');
        break;
      case StoryTimelinePrFilter.volume:
        query = query.where('prTypes', arrayContains: 'volume');
        break;
      case StoryTimelinePrFilter.all:
        break;
    }

    if (filter.gymId != null && filter.gymId!.isNotEmpty) {
      query = query.where('gymId', isEqualTo: filter.gymId);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final cachePreferred = preferCache
        ? const GetOptions(source: Source.cache)
        : const GetOptions(source: Source.serverAndCache);
    var snapshot = await query.get(cachePreferred);
    if (preferCache && snapshot.docs.isEmpty) {
      snapshot = await query.get(const GetOptions(source: Source.serverAndCache));
    }
    final docs = snapshot.docs;
    final entries = docs.map(StoryTimelineEntry.fromDoc).toList();
    final hasMore = docs.length == limit;
    final lastDoc = docs.isEmpty ? null : docs.last;
    return StoryTimelinePage(entries: entries, lastDocument: lastDoc, hasMore: hasMore);
  }

  Stream<StoryTimelineMetrics> watchMetrics(String userId) {
    if (userId.isEmpty) {
      return const Stream.empty();
    }
    return _metrics(userId)
        .snapshots(includeMetadataChanges: true)
        .map(StoryTimelineMetrics.fromSnapshot);
  }

  DateTime? _rangeStart(StoryTimelineRange range, DateTime now) {
    final normalized = DateTime(now.year, now.month, now.day);
    switch (range) {
      case StoryTimelineRange.last30Days:
        return normalized.subtract(const Duration(days: 30));
      case StoryTimelineRange.last90Days:
        return normalized.subtract(const Duration(days: 90));
      case StoryTimelineRange.thisYear:
        return DateTime(normalized.year, 1, 1);
      case StoryTimelineRange.allTime:
        return null;
    }
  }
}
