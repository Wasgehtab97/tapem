class NutritionMacros {
  final int protein;
  final int carbs;
  final int fat;

  const NutritionMacros({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory NutritionMacros.fromMap(Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    return NutritionMacros(
      protein: (map['protein'] as num?)?.round() ?? 0,
      carbs: (map['carbs'] as num?)?.round() ?? 0,
      fat: (map['fat'] as num?)?.round() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };
}
