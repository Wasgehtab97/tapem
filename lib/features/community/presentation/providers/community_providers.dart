import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/time_windows.dart';
import '../../data/firestore_community_stats_source.dart';
import '../../domain/models/community_stats.dart';
import '../../domain/models/feed_event.dart';
import '../../domain/services/community_stats_service.dart';

enum CommunityPeriod { today, week, month }

class UtcRange {
  const UtcRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

final currentGymIdProvider = Provider<String>((ref) {
  throw UnimplementedError('Provide at app root');
});

final communityStatsServiceProvider = Provider<CommunityStatsService>((ref) {
  return CommunityStatsService(
    FirestoreCommunityStatsSource(),
  );
});

UtcRange periodToUtcRange(
  CommunityPeriod period, {
  DateTime? now,
  TimeZoneOffsetResolver? offsetResolver,
}) {
  final resolvedNow = now ?? DateTime.now();
  final window = switch (period) {
    CommunityPeriod.today => todayUtcRange(resolvedNow, offsetResolver: offsetResolver),
    CommunityPeriod.week => weekUtcRange(resolvedNow, offsetResolver: offsetResolver),
    CommunityPeriod.month => monthUtcRange(resolvedNow, offsetResolver: offsetResolver),
  };
  return UtcRange(start: window.startUtc, end: window.endUtc);
}

final communityStatsProvider = StreamProvider.autoDispose
    .family<CommunityStats, CommunityPeriod>((ref, period) {
  final gymId = ref.watch(currentGymIdProvider);
  final service = ref.watch(communityStatsServiceProvider);
  if (gymId.isEmpty) {
    return Stream.value(CommunityStats.zero);
  }
  final range = periodToUtcRange(period);
  return service.streamRange(
    gymId: gymId,
    startUtc: range.start,
    endUtc: range.end,
  );
}, dependencies: [currentGymIdProvider, communityStatsServiceProvider]);

final communityFeedProvider = StreamProvider.autoDispose<List<FeedEvent>>((ref) {
  final gymId = ref.watch(currentGymIdProvider);
  final service = ref.watch(communityStatsServiceProvider);
  if (gymId.isEmpty) {
    return Stream.value(const <FeedEvent>[]);
  }
  return service.streamFeed(gymId: gymId, limit: 20);
}, dependencies: [currentGymIdProvider, communityStatsServiceProvider]);
