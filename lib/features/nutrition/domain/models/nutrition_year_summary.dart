class NutritionYearSummary {
  final int year;
  final Map<String, NutritionYearDay> days;

  const NutritionYearSummary({
    required this.year,
    required this.days,
  });

  factory NutritionYearSummary.fromMap(int year, Map<String, dynamic> data) {
    final rawDays = (data['days'] as Map<String, dynamic>? ?? {});
    final days = <String, NutritionYearDay>{};
    for (final entry in rawDays.entries) {
      final value = entry.value;
      if (value is String) {
        days[entry.key] = NutritionYearDay(status: value, goal: 0, total: 0);
      } else if (value is Map<String, dynamic>) {
        days[entry.key] = NutritionYearDay.fromMap(value);
      }
    }
    return NutritionYearSummary(year: year, days: days);
  }

  Map<String, dynamic> toMap() => {
        'days': days.map((k, v) => MapEntry(k, v.toMap())),
      };
}

class NutritionYearDay {
  final String status;
  final int goal;
  final int total;

  const NutritionYearDay({
    required this.status,
    required this.goal,
    required this.total,
  });

  factory NutritionYearDay.fromMap(Map<String, dynamic> data) {
    return NutritionYearDay(
      status: data['status'] as String? ?? 'unknown',
      goal: data['goal'] as int? ?? 0,
      total: data['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status,
        'goal': goal,
        'total': total,
      };
}
