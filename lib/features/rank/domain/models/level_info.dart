class LevelInfo {
  final int level;
  final int xp;
  LevelInfo({required this.level, required this.xp});

  LevelInfo copyWith({int? level, int? xp}) =>
      LevelInfo(level: level ?? this.level, xp: xp ?? this.xp);

  factory LevelInfo.initial() => LevelInfo(level: 1, xp: 0);

  factory LevelInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) return LevelInfo.initial();
    return LevelInfo(
      level: map['level'] as int? ?? 1,
      xp: map['xp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'level': level, 'xp': xp};
}
