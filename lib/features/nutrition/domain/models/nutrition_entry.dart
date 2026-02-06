class NutritionEntry {
  final String name;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final String meal;
  final String? barcode;
  final String? recipeId;
  final double? qty;

  const NutritionEntry({
    required this.name,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.meal,
    this.barcode,
    this.recipeId,
    this.qty,
  });

  factory NutritionEntry.fromMap(Map<String, dynamic> data) {
    return NutritionEntry(
      name: data['name'] as String? ?? '',
      kcal: (data['kcal'] as num?)?.round() ?? 0,
      protein: (data['protein'] as num?)?.round() ?? 0,
      carbs: (data['carbs'] as num?)?.round() ?? 0,
      fat: (data['fat'] as num?)?.round() ?? 0,
      meal: data['meal'] as String? ?? 'unspecified',
      barcode: data['barcode'] as String?,
      recipeId: data['recipeId'] as String?,
      qty: (data['qty'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'kcal': kcal,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'meal': meal,
    if (barcode != null) 'barcode': barcode,
    if (recipeId != null) 'recipeId': recipeId,
    if (qty != null) 'qty': qty,
  };
}
