class NutritionWeightBucket {
  final String id;
  final DateTime start;
  final DateTime end;
  final String label;
  final double avgKg;
  final int sampleCount;

  const NutritionWeightBucket({
    required this.id,
    required this.start,
    required this.end,
    required this.label,
    required this.avgKg,
    required this.sampleCount,
  });
}
