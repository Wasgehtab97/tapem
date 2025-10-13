class ExerciseMuscleMap {
  static const Map<String, List<String>> _map = {
    'bench_press': ['pecs', 'triceps'],
    'bench': ['pecs', 'triceps'],
    'back_squat': ['quads', 'glutes', 'hamstrings'],
    'front_squat': ['quads', 'glutes'],
    'deadlift': ['hamstrings', 'glutes', 'spinal_erectors'],
    'lat_pulldown': ['lats', 'biceps'],
    'pull_up': ['lats', 'biceps'],
    'overhead_press': ['shoulders', 'triceps'],
    'shoulder_press': ['shoulders', 'triceps'],
    'barbell_row': ['upper_back', 'lats', 'biceps'],
    'seated_row': ['upper_back', 'lats', 'biceps'],
    'leg_press': ['quads', 'glutes'],
    'leg_extension': ['quads'],
    'leg_curl': ['hamstrings'],
    'hip_thrust': ['glutes', 'hamstrings'],
    'romanian_deadlift': ['hamstrings', 'glutes', 'spinal_erectors'],
    'bicep_curl': ['biceps'],
    'tricep_pushdown': ['triceps'],
    'dumbbell_fly': ['pecs'],
    'chest_fly': ['pecs'],
    'lateral_raise': ['shoulders'],
    'calf_raise': ['calves'],
    'ab_wheel': ['core'],
    'plank': ['core'],
    'bench_dip': ['triceps', 'pecs'],
    'push_up': ['pecs', 'triceps', 'shoulders'],
    'machine_row': ['upper_back', 'lats', 'biceps'],
  };

  static List<String> lookup(String exerciseId) {
    final normalized = exerciseId.trim().toLowerCase();
    return List.unmodifiable(_map[normalized] ?? const []);
  }
}
