class PlannedSet {
  final double weight;
  final int reps;
  final int? rir;
  final String? note;

  PlannedSet({required this.weight, required this.reps, this.rir, this.note});

  factory PlannedSet.fromMap(Map<String, dynamic> map) => PlannedSet(
    weight: (map['weight'] as num?)?.toDouble() ?? 0,
    reps: (map['reps'] as num?)?.toInt() ?? 0,
    rir: (map['rir'] as num?)?.toInt(),
    note: map['note'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'weight': weight,
    'reps': reps,
    if (rir != null) 'rir': rir,
    if (note != null && note!.isNotEmpty) 'note': note,
  };
}
