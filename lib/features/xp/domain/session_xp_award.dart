import 'device_xp_result.dart';

/// Result returned after attempting to award XP for a session.
class SessionXpAward {
  const SessionXpAward({
    required this.result,
    this.totalXp,
    this.dayXp,
    this.xpDelta = 0,
    this.components = const [],
    this.penalties = const [],
  });

  /// Outcome of the device leaderboard write.
  final DeviceXpResult result;

  /// Aggregated XP total for daily progression after the operation.
  final int? totalXp;

  /// XP that has been booked for the specific training day.
  final int? dayXp;

  /// Net delta applied to the aggregated daily XP total.
  final int xpDelta;

  /// Serialized breakdown of the XP components that built [dayXp].
  final List<Map<String, dynamic>> components;

  /// Serialized information about penalty events that were written.
  final List<Map<String, dynamic>> penalties;

  SessionXpAward copyWith({
    DeviceXpResult? result,
    int? totalXp,
    bool unsetTotalXp = false,
    int? dayXp,
    bool unsetDayXp = false,
    int? xpDelta,
    List<Map<String, dynamic>>? components,
    List<Map<String, dynamic>>? penalties,
  }) {
    return SessionXpAward(
      result: result ?? this.result,
      totalXp: unsetTotalXp
          ? null
          : (totalXp ?? this.totalXp),
      dayXp: unsetDayXp ? null : (dayXp ?? this.dayXp),
      xpDelta: xpDelta ?? this.xpDelta,
      components: components ?? this.components,
      penalties: penalties ?? this.penalties,
    );
  }
}
