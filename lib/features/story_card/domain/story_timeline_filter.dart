import 'package:flutter/foundation.dart';

enum StoryTimelinePrFilter { all, prsOnly, firsts, strength, volume }

enum StoryTimelineRange { last30Days, last90Days, thisYear, allTime }

@immutable
class StoryTimelineFilter {
  final StoryTimelinePrFilter prFilter;
  final StoryTimelineRange range;
  final String? gymId;

  const StoryTimelineFilter({
    this.prFilter = StoryTimelinePrFilter.all,
    this.range = StoryTimelineRange.last30Days,
    this.gymId,
  });

  StoryTimelineFilter copyWith({
    StoryTimelinePrFilter? prFilter,
    StoryTimelineRange? range,
    String? gymId,
    bool resetGym = false,
  }) {
    return StoryTimelineFilter(
      prFilter: prFilter ?? this.prFilter,
      range: range ?? this.range,
      gymId: resetGym ? null : (gymId ?? this.gymId),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StoryTimelineFilter) return false;
    return other.prFilter == prFilter && other.range == range && other.gymId == gymId;
  }

  @override
  int get hashCode => Object.hash(prFilter, range, gymId);
}
