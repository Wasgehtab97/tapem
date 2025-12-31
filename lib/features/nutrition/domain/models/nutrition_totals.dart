class NutritionTotals {
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;

  const NutritionTotals({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory NutritionTotals.fromMap(Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    return NutritionTotals(
      kcal: (map['kcal'] as num?)?.round() ?? 0,
      protein: (map['protein'] as num?)?.round() ?? 0,
      carbs: (map['carbs'] as num?)?.round() ?? 0,
      fat: (map['fat'] as num?)?.round() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'kcal': kcal,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };
}
