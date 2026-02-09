class DayXpComponentBreakdown {
  const DayXpComponentBreakdown({
    required this.code,
    required this.amount,
    this.metadata = const <String, dynamic>{},
  });

  final String code;
  final int amount;
  final Map<String, dynamic> metadata;
}

class DayXpPenaltyBreakdown {
  const DayXpPenaltyBreakdown({
    required this.id,
    required this.type,
    required this.xpDelta,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String type;
  final int xpDelta;
  final Map<String, dynamic> metadata;
}

class DayXpBreakdown {
  const DayXpBreakdown({
    required this.dayKey,
    required this.dayXp,
    this.components = const <DayXpComponentBreakdown>[],
    this.penalties = const <DayXpPenaltyBreakdown>[],
    this.rulesetId,
    this.rulesetVersion,
  });

  const DayXpBreakdown.empty({
    this.dayKey = '',
    this.dayXp = 0,
    this.components = const <DayXpComponentBreakdown>[],
    this.penalties = const <DayXpPenaltyBreakdown>[],
    this.rulesetId,
    this.rulesetVersion,
  });

  final String dayKey;
  final int dayXp;
  final List<DayXpComponentBreakdown> components;
  final List<DayXpPenaltyBreakdown> penalties;
  final String? rulesetId;
  final int? rulesetVersion;

  bool get hasDetails => components.isNotEmpty || penalties.isNotEmpty;
}
