import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/models/community_stats.dart';
import '../domain/models/feed_event.dart';

class FirestoreCommunityStatsSource {
  FirestoreCommunityStatsSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<CommunityStats> streamDailyStats({
    required String gymId,
    required String dayKey,
  }) {
    if (gymId.isEmpty || dayKey.isEmpty) {
      return Stream.value(CommunityStats.zero.copyWith(dayKey: dayKey));
    }
    final ref = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('stats_daily')
        .doc(dayKey);
    return ref.snapshots().map((doc) => _mapStats(doc, fallbackDayKey: dayKey));
  }

  Future<List<CommunityStats>> loadStatsForRange({
    required String gymId,
    required DateTime startUtc,
    required DateTime endUtc,
  }) async {
    if (gymId.isEmpty) {
      return const [];
    }
    final collection = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('stats_daily');
    final query = collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startUtc))
        .where('date', isLessThan: Timestamp.fromDate(endUtc))
        .orderBy('date');
    try {
      final snap = await query.get();
      return snap.docs.map(_mapStats).toList();
    } on FirebaseException catch (e, st) {
      debugPrint(
        '[FirestoreCommunityStatsSource] loadStatsForRange error code=${e.code} message=${e.message}',
      );
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  Stream<List<CommunityStats>> streamStatsForRange({
    required String gymId,
    required DateTime startUtc,
    required DateTime endUtc,
  }) {
    if (gymId.isEmpty) {
      return Stream.value(const <CommunityStats>[]);
    }
    final collection = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('stats_daily');
    final query = collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startUtc))
        .where('date', isLessThan: Timestamp.fromDate(endUtc))
        .orderBy('date');
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map(_mapStats).toList(growable: false);
    }).handleError((error, stackTrace) {
      if (error is FirebaseException) {
        debugPrint(
          '[FirestoreCommunityStatsSource] streamStatsForRange error code=${error.code} message=${error.message}',
        );
        debugPrintStack(stackTrace: stackTrace);
      } else {
        debugPrint('[FirestoreCommunityStatsSource] streamStatsForRange error $error');
      }
    });
  }

  Stream<List<FeedEvent>> streamFeed({
    required String gymId,
    int limit = 20,
  }) {
    if (gymId.isEmpty) {
      return Stream.value(const <FeedEvent>[]);
    }
    final query = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('feed_events')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(_mapFeedEvent).toList(growable: false),
    ).handleError((error, stackTrace) {
      if (error is FirebaseException) {
        debugPrint(
          '[FirestoreCommunityStatsSource] streamFeed error code=${error.code} message=${error.message}',
        );
        debugPrintStack(stackTrace: stackTrace);
      } else {
        debugPrint('[FirestoreCommunityStatsSource] streamFeed error $error');
      }
    });
  }

  Future<List<FeedEvent>> loadFeedEventsByDayKeyRange({
    required String gymId,
    required String startDayKey,
    required String endDayKey,
  }) async {
    if (gymId.isEmpty) {
      return const <FeedEvent>[];
    }
    final query = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('feed_events')
        .where('dayKey', isGreaterThanOrEqualTo: startDayKey)
        .where('dayKey', isLessThanOrEqualTo: endDayKey)
        .orderBy('dayKey');
    try {
      final snapshot = await query.get();
      return snapshot.docs.map(_mapFeedEvent).toList(growable: false);
    } on FirebaseException catch (e, st) {
      debugPrint(
        '[FirestoreCommunityStatsSource] loadFeedEventsByDayKeyRange error code=${e.code} message=${e.message}',
      );
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  CommunityStats _mapStats(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String? fallbackDayKey,
  }) {
    final data = doc.data();
    if (data == null) {
      return CommunityStats.zero.copyWith(dayKey: fallbackDayKey ?? doc.id);
    }
    final reps = (data['repsTotal'] as num?)?.toInt() ?? 0;
    final volume = (data['volumeTotal'] as num?)?.toDouble() ?? 0;
    final sessions = (data['trainingSessions'] as num?)?.toInt() ?? 0;
    final exercises = (data['exerciseTotal'] as num?)?.toInt() ?? 0;
    final sets = (data['setTotal'] as num?)?.toInt() ?? 0;
    final ts = data['date'];
    DateTime? date;
    if (ts is Timestamp) {
      date = ts.toDate();
    }
    final resolvedDayKey = (data['dayKey'] as String?) ?? doc.id;
    return CommunityStats(
      totalSessions: sessions,
      totalExercises: exercises,
      totalSets: sets,
      totalReps: reps,
      totalVolumeKg: volume,
      dayKey: resolvedDayKey,
      date: date,
    );
  }

  FeedEvent _mapFeedEvent(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      return FeedEvent(
        type: FeedEventType.daySummary,
        dayKey: _extractDayKey(doc.id),
      );
    }
    final created = data['createdAt'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    }
    final typeString = data['type'] as String?;
    final eventType = feedEventTypeFromString(typeString);
    return FeedEvent(
      type: eventType,
      createdAt: createdAt,
      dayKey: (data['dayKey'] as String?) ?? _extractDayKey(doc.id),
    );
  }
}

String _extractDayKey(String docId) {
  final separatorIndex = docId.indexOf('_');
  if (separatorIndex <= 0) {
    return docId;
  }
  return docId.substring(0, separatorIndex);
}
