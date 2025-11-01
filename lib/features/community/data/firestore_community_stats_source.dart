import 'package:cloud_firestore/cloud_firestore.dart';

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
    final snap = await query.get();
    return snap.docs.map(_mapStats).toList();
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
        );
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
    final ts = data['date'];
    DateTime? date;
    if (ts is Timestamp) {
      date = ts.toDate();
    }
    final resolvedDayKey = (data['dayKey'] as String?) ?? doc.id;
    return CommunityStats(
      totalReps: reps,
      totalVolumeKg: volume,
      workoutCount: sessions,
      dayKey: resolvedDayKey,
      date: date,
    );
  }

  FeedEvent _mapFeedEvent(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      return FeedEvent(
        type: FeedEventType.sessionSummary,
        dayKey: '',
        reps: 0,
        volumeKg: 0,
      );
    }
    final created = data['createdAt'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    }
    return FeedEvent(
      type: feedEventTypeFromString(data['type'] as String?),
      createdAt: createdAt,
      userId: data['userId'] as String?,
      username: data['username'] as String?,
      dayKey: (data['dayKey'] as String?) ?? '',
      reps: (data['reps'] as num?)?.toInt() ?? 0,
      volumeKg: (data['volume'] as num?)?.toDouble() ?? 0,
      deviceName: data['deviceName'] as String?,
      funnyText: data['funnyText'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
    );
  }
}
