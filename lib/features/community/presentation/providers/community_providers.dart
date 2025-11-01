import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/time_windows.dart';
import '../../data/firestore_community_stats_source.dart';
import '../../domain/models/community_stats.dart';
import '../../domain/models/feed_event.dart';
import '../../domain/services/community_stats_service.dart';

final communityStatsServiceProvider = Provider<CommunityStatsService>((ref) {
  final source = FirestoreCommunityStatsSource();
  return CommunityStatsService(source);
});

final communityGymIdProvider = Provider<String>((ref) {
  throw StateError('communityGymIdProvider must be overridden.');
});

final communityNowProvider = Provider<DateTime>((ref) => DateTime.now());

final communityTodayProvider =
    StreamProvider.autoDispose<CommunityStats>((ref) {
  ref.keepAlive();
  final gymId = ref.watch(communityGymIdProvider);
  if (gymId.isEmpty) {
    return Stream.value(CommunityStats.zero);
  }
  final service = ref.watch(communityStatsServiceProvider);
  return service.streamToday(gymId);
});

final communityWeekProvider =
    FutureProvider.autoDispose<CommunityStats>((ref) async {
  ref.keepAlive();
  final gymId = ref.watch(communityGymIdProvider);
  if (gymId.isEmpty) {
    return CommunityStats.zero;
  }
  final service = ref.watch(communityStatsServiceProvider);
  final now = ref.watch(communityNowProvider);
  final window = weekUtcRange(now);
  return service.loadPeriod(gymId, window);
});

final communityMonthProvider =
    FutureProvider.autoDispose<CommunityStats>((ref) async {
  ref.keepAlive();
  final gymId = ref.watch(communityGymIdProvider);
  if (gymId.isEmpty) {
    return CommunityStats.zero;
  }
  final service = ref.watch(communityStatsServiceProvider);
  final now = ref.watch(communityNowProvider);
  final window = monthUtcRange(now);
  return service.loadPeriod(gymId, window);
});

final communityFeedProvider =
    StreamProvider.autoDispose<List<FeedEvent>>((ref) {
  ref.keepAlive();
  final gymId = ref.watch(communityGymIdProvider);
  if (gymId.isEmpty) {
    return Stream.value(const <FeedEvent>[]);
  }
  final service = ref.watch(communityStatsServiceProvider);
  return service.streamFeed(gymId, limit: 20);
});
