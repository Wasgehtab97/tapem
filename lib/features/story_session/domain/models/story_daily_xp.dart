import 'package:equatable/equatable.dart';

/// Human-readable breakdown of how a training day XP total was composed.
class StoryXpComponent extends Equatable {
  final String code;
  final int amount;
  final Map<String, dynamic> metadata;

  const StoryXpComponent({
    required this.code,
    required this.amount,
    this.metadata = const {},
  });

  factory StoryXpComponent.fromJson(Map<String, dynamic> json) {
    final code = (json['code'] as String?)?.trim();
    final amount = (json['amount'] as num?)?.toInt();
    return StoryXpComponent(
      code: code == null || code.isEmpty ? 'unknown' : code,
      amount: amount ?? 0,
      metadata: _readMetadata(json['metadata']),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'amount': amount,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  StoryXpComponent copyWith({
    String? code,
    int? amount,
    Map<String, dynamic>? metadata,
  }) {
    return StoryXpComponent(
      code: code ?? this.code,
      amount: amount ?? this.amount,
      metadata: metadata ?? this.metadata,
    );
  }

  static Map<String, dynamic> _readMetadata(dynamic raw) {
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value));
    }
    return const {};
  }

  @override
  List<Object?> get props => [code, amount, metadata];
}

/// Captures penalty events that influenced the running XP total.
class StoryXpPenalty extends Equatable {
  final String id;
  final String type;
  final int delta;
  final String day;
  final Map<String, dynamic> metadata;

  const StoryXpPenalty({
    required this.id,
    required this.type,
    required this.delta,
    required this.day,
    this.metadata = const {},
  });

  factory StoryXpPenalty.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim();
    final type = (json['type'] as String?)?.trim();
    final delta = (json['xpDelta'] as num?)?.toInt();
    final day = (json['day'] as String?)?.trim();
    return StoryXpPenalty(
      id: id == null || id.isEmpty ? 'unknown' : id,
      type: type == null || type.isEmpty ? 'unknown' : type,
      delta: delta ?? 0,
      day: day == null || day.isEmpty ? 'unknown' : day,
      metadata: StoryXpComponent._readMetadata(json['metadata']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'xpDelta': delta,
        'day': day,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  StoryXpPenalty copyWith({
    String? id,
    String? type,
    int? delta,
    String? day,
    Map<String, dynamic>? metadata,
  }) {
    return StoryXpPenalty(
      id: id ?? this.id,
      type: type ?? this.type,
      delta: delta ?? this.delta,
      day: day ?? this.day,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [id, type, delta, day, metadata];
}

/// Aggregated view of the training day XP amount, components and penalties.
class StoryDailyXp extends Equatable {
  final int xp;
  final int? totalXp;
  final int? computedTotalXp;
  final int? runningTotalXp;
  final Map<String, dynamic> metadata;
  final List<StoryXpComponent> components;
  final List<StoryXpPenalty> penalties;

  const StoryDailyXp({
    required this.xp,
    this.totalXp,
    this.computedTotalXp,
    this.runningTotalXp,
    this.metadata = const {},
    this.components = const [],
    this.penalties = const [],
  });

  const StoryDailyXp.empty()
      : xp = 0,
        totalXp = null,
        computedTotalXp = null,
        runningTotalXp = null,
        metadata = const {},
        components = const [],
        penalties = const [];

  bool get hasBreakdown => components.isNotEmpty || penalties.isNotEmpty;

  int get penaltySum {
    if (penalties.isEmpty) return 0;
    return penalties.fold(0, (sum, penalty) => sum + penalty.delta);
  }

  int? get previousTotalXp {
    final baseline = runningTotalXp ?? computedTotalXp ?? totalXp;
    if (baseline == null) return null;
    return baseline - xp - penaltySum;
  }

  int? get netXpDelta {
    final total = totalXp ?? computedTotalXp ?? runningTotalXp;
    final previous = previousTotalXp;
    if (total != null && previous != null) {
      return total - previous;
    }
    final floorDelta =
        totalXp != null && computedTotalXp != null ? totalXp! - computedTotalXp! : 0;
    return xp + penaltySum + floorDelta;
  }

  bool get floorApplied =>
      totalXp != null && computedTotalXp != null && totalXp! > computedTotalXp!;

  StoryDailyXp copyWith({
    int? xp,
    int? totalXp,
    bool unsetTotalXp = false,
    int? computedTotalXp,
    bool unsetComputedTotalXp = false,
    int? runningTotalXp,
    bool unsetRunningTotalXp = false,
    Map<String, dynamic>? metadata,
    List<StoryXpComponent>? components,
    List<StoryXpPenalty>? penalties,
  }) {
    return StoryDailyXp(
      xp: xp ?? this.xp,
      totalXp: unsetTotalXp ? null : (totalXp ?? this.totalXp),
      computedTotalXp:
          unsetComputedTotalXp ? null : (computedTotalXp ?? this.computedTotalXp),
      runningTotalXp:
          unsetRunningTotalXp ? null : (runningTotalXp ?? this.runningTotalXp),
      metadata: metadata ?? this.metadata,
      components: components ?? this.components,
      penalties: penalties ?? this.penalties,
    );
  }

  Map<String, dynamic> toJson() => {
        'xp': xp,
        if (totalXp != null) 'totalXp': totalXp,
        if (computedTotalXp != null) 'computedTotalXp': computedTotalXp,
        if (runningTotalXp != null) 'runningTotalXp': runningTotalXp,
        if (metadata.isNotEmpty) 'metadata': metadata,
        if (components.isNotEmpty)
          'components': components.map((c) => c.toJson()).toList(),
        if (penalties.isNotEmpty)
          'penalties': penalties.map((p) => p.toJson()).toList(),
      };

  factory StoryDailyXp.fromJson(Map<String, dynamic> json) {
    final xp = (json['xp'] as num?)?.toInt() ?? 0;
    final totalXp = (json['totalXp'] as num?)?.toInt();
    final computedTotalXp = (json['computedTotalXp'] as num?)?.toInt();
    final runningTotalXp = (json['runningTotalXp'] as num?)?.toInt();
    final metadata = StoryXpComponent._readMetadata(json['metadata']);
    final rawComponents = json['components'];
    final components = rawComponents is List
        ? rawComponents
            .whereType<Map>()
            .map((raw) => StoryXpComponent.fromJson(
                  raw.map((key, value) => MapEntry('$key', value)),
                ))
            .toList()
        : const <StoryXpComponent>[];
    final rawPenalties = json['penalties'];
    final penalties = rawPenalties is List
        ? rawPenalties
            .whereType<Map>()
            .map((raw) => StoryXpPenalty.fromJson(
                  raw.map((key, value) => MapEntry('$key', value)),
                ))
            .toList()
        : const <StoryXpPenalty>[];
    return StoryDailyXp(
      xp: xp,
      totalXp: totalXp,
      computedTotalXp: computedTotalXp,
      runningTotalXp: runningTotalXp,
      metadata: metadata,
      components: components,
      penalties: penalties,
    );
  }

  @override
  List<Object?> get props => [
        xp,
        totalXp,
        computedTotalXp,
        runningTotalXp,
        metadata,
        components,
        penalties,
      ];
}
