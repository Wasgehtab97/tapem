enum FeedEventType { daySummary, milestone }

FeedEventType feedEventTypeFromString(String? type) {
  switch (type) {
    case 'milestone':
      return FeedEventType.milestone;
    case 'day_summary':
    case 'session_summary':
    default:
      return FeedEventType.daySummary;
  }
}

class FeedEvent {
  const FeedEvent({
    required this.type,
    required this.dayKey,
    this.createdAt,
  });

  final FeedEventType type;
  final DateTime? createdAt;
  final String dayKey;
}
