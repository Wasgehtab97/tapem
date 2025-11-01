enum FeedEventType { sessionSummary, milestone }

FeedEventType feedEventTypeFromString(String? type) {
  switch (type) {
    case 'milestone':
      return FeedEventType.milestone;
    case 'session_summary':
    default:
      return FeedEventType.sessionSummary;
  }
}

class FeedEvent {
  const FeedEvent({
    required this.type,
    required this.dayKey,
    required this.reps,
    required this.volumeKg,
    this.createdAt,
    this.userId,
    this.username,
    this.deviceName,
    this.funnyText,
    this.avatarUrl,
  });

  final FeedEventType type;
  final DateTime? createdAt;
  final String? userId;
  final String? username;
  final String dayKey;
  final int reps;
  final double volumeKg;
  final String? deviceName;
  final String? funnyText;
  final String? avatarUrl;

  String? get displayName {
    final trimmed = username?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
