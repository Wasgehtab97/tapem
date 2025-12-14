class ClientCoachingAnalytics {
  const ClientCoachingAnalytics({
    required this.totalCompletions,
    required this.totalPlans,
    required this.avgSessionsPerWeek,
    required this.lastActivity,
  });

  final int totalCompletions;
  final int totalPlans;
  final double avgSessionsPerWeek;
  final DateTime? lastActivity;

  bool get hasData => totalCompletions > 0;

  factory ClientCoachingAnalytics.empty() => const ClientCoachingAnalytics(
        totalCompletions: 0,
        totalPlans: 0,
        avgSessionsPerWeek: 0,
        lastActivity: null,
      );
}

