import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
    return stream.map((stats) => stats.copyWith(dayKey: dayKey)).handleError(
      (error, stackTrace) => _logError('streamToday', error, stackTrace),
    );
  }

  Future<CommunityStats> loadPeriod(String gymId, TimeWindow window) async {
    if (gymId.isEmpty || !window.isValid) {
      return CommunityStats.zero;
    }
    late final List<CommunityStats> entries;
    try {
      entries = await _source.loadStatsForRange(
        gymId: gymId,
        startUtc: window.startUtc,
        endUtc: window.endUtc,
      );
    } on FirebaseException catch (error, stackTrace) {
      _logError('loadPeriod', error, stackTrace);
      rethrow;
    }
    if (entries.isEmpty) {
      return CommunityStats.zero;
    }
    return entries.reduce((value, element) => value + element);
  }

  Stream<List<FeedEvent>> streamFeed(String gymId, {int limit = 20}) {
    return _source.streamFeed(gymId: gymId, limit: limit).handleError(
      (error, stackTrace) => _logError('streamFeed', error, stackTrace),
    );
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

  Stream<CommunityStats> streamRange({
    required String gymId,
    required DateTime startUtc,
    required DateTime endUtc,
  }) {
    if (gymId.isEmpty) {
      return Stream.value(CommunityStats.zero);
    }
    final stream = _source.streamStatsForRange(
      gymId: gymId,
      startUtc: startUtc,
      endUtc: endUtc,
    );
    return stream.map((entries) {
      if (entries.isEmpty) {
        return CommunityStats.zero;
      }
      return entries.reduce((value, element) => value + element);
    }).handleError((error, stackTrace) => _logError('streamRange', error, stackTrace));
  }

  void _logError(String method, Object error, StackTrace stackTrace) {
    if (error is FirebaseException) {
      debugPrint(
        '[CommunityStatsService] $method error code=${error.code} message=${error.message}',
      );
    } else {
      debugPrint('[CommunityStatsService] $method error $error');
    }
    debugPrintStack(stackTrace: stackTrace);
  }
}
