class NutritionYearSummary {
  final int year;
  final Map<String, String> days;

  const NutritionYearSummary({
    required this.year,
    required this.days,
  });

  factory NutritionYearSummary.fromMap(int year, Map<String, dynamic> data) {
    final rawDays = (data['days'] as Map<String, dynamic>? ?? {});
    final days = <String, String>{};
    for (final entry in rawDays.entries) {
      final value = entry.value;
      if (value is String) {
        days[entry.key] = value;
      }
    }
    return NutritionYearSummary(year: year, days: days);
  }

  Map<String, dynamic> toMap() => {
    'days': days,
  };
}
