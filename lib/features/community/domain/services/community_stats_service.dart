import 'dart:async';

import 'package:meta/meta.dart';

import '../../../../core/time/logic_day.dart';
import '../../../../core/time/time_windows.dart';
import '../../data/firestore_community_stats_source.dart';
import '../models/community_stats.dart';
import '../models/feed_event.dart';

typedef Clock = DateTime Function();

class CommunityStatsService {
  CommunityStatsService(
    this._source, {
    Clock? clock,
  }) : _clock = clock ?? DateTime.now;

  final FirestoreCommunityStatsSource _source;
  final Clock _clock;

  Stream<CommunityStats> streamToday(String gymId) {
    final now = _clock();
    final dayKey = logicDayKey(now);
    final stream = _source.streamDailyStats(gymId: gymId, dayKey: dayKey);
    return stream.map((stats) => stats.copyWith(dayKey: dayKey));
  }

  Future<CommunityStats> loadPeriod(String gymId, TimeWindow window) async {
    if (gymId.isEmpty || !window.isValid) {
      return CommunityStats.zero;
    }
    final entries = await _source.loadStatsForRange(
      gymId: gymId,
      startUtc: window.startUtc,
      endUtc: window.endUtc,
    );
    if (entries.isEmpty) {
      return CommunityStats.zero;
    }
    return entries.reduce((value, element) => value + element);
  }

  Stream<List<FeedEvent>> streamFeed(String gymId, {int limit = 20}) {
    return _source.streamFeed(gymId: gymId, limit: limit);
  }

  @visibleForTesting
  Future<CommunityStats> loadTimeframe(
    String gymId,
    Timeframe timeframe,
  ) {
    final now = _clock();
    final window = periodUtcRange(now, timeframe: timeframe);
    return loadPeriod(gymId, window);
  }
}
