class ExerciseEntry {
  final String deviceId;
  final String exerciseId;
  final String setType; // z.B. Warmup, Arbeits-Satz
  final int totalSets;
  final int workSets;
  final int? reps;
  final double? weight;
  final int rir;
  final int restInSeconds;
  final String? notes;

  ExerciseEntry({
    required this.deviceId,
    required this.exerciseId,
    required this.setType,
    required this.totalSets,
    required this.workSets,
    this.reps,
    this.weight,
    required this.rir,
    required this.restInSeconds,
    this.notes,
  });

  factory ExerciseEntry.fromMap(Map<String, dynamic> map) => ExerciseEntry(
    deviceId: map['deviceId'] as String,
    exerciseId: map['exerciseId'] as String,
    setType: map['setType'] as String? ?? '',
    totalSets: (map['totalSets'] as num?)?.toInt() ?? 0,
    workSets: (map['workSets'] as num?)?.toInt() ?? 0,
    reps: (map['reps'] as num?)?.toInt(),
    weight: (map['weight'] as num?)?.toDouble(),
    rir: (map['rir'] as num?)?.toInt() ?? 0,
    restInSeconds: (map['restInSeconds'] as num?)?.toInt() ?? 0,
    notes: map['notes'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'deviceId': deviceId,
    'exerciseId': exerciseId,
    'setType': setType,
    'totalSets': totalSets,
    'workSets': workSets,
    if (reps != null) 'reps': reps,
    if (weight != null) 'weight': weight,
    'rir': rir,
    'restInSeconds': restInSeconds,
    if (notes != null) 'notes': notes,
  };
}
