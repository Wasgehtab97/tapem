class RecipeIngredient {
  final String name;
  final String? barcode;
  final int kcalPer100;
  final int proteinPer100;
  final int carbsPer100;
  final int fatPer100;
  final double grams;

  const RecipeIngredient({
    required this.name,
    this.barcode,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.carbsPer100,
    required this.fatPer100,
    required this.grams,
  });

  factory RecipeIngredient.fromMap(Map<String, dynamic> data) {
    return RecipeIngredient(
      name: data['name'] as String? ?? '',
      barcode: data['barcode'] as String?,
      kcalPer100: (data['kcalPer100'] as num?)?.round() ?? 0,
      proteinPer100: (data['proteinPer100'] as num?)?.round() ?? 0,
      carbsPer100: (data['carbsPer100'] as num?)?.round() ?? 0,
      fatPer100: (data['fatPer100'] as num?)?.round() ?? 0,
      grams: (data['grams'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        if (barcode != null) 'barcode': barcode,
        'kcalPer100': kcalPer100,
        'proteinPer100': proteinPer100,
        'carbsPer100': carbsPer100,
        'fatPer100': fatPer100,
        'grams': grams,
      };
}

class NutritionRecipe {
  final String id;
  final String name;
  final List<RecipeIngredient> ingredients;
  final DateTime? updatedAt;

  const NutritionRecipe({
    required this.id,
    required this.name,
    required this.ingredients,
    this.updatedAt,
  });

  factory NutritionRecipe.fromMap(String id, Map<String, dynamic> data) {
    final ing = (data['ingredients'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(RecipeIngredient.fromMap)
        .toList();
    DateTime? updated;
    final rawUpdated = data['updatedAt'];
    if (rawUpdated is String) {
      updated = DateTime.tryParse(rawUpdated);
    }
    return NutritionRecipe(
      id: id,
      name: data['name'] as String? ?? '',
      ingredients: ing,
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'ingredients': ingredients.map((e) => e.toMap()).toList(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  NutritionRecipe copyWith({
    String? id,
    String? name,
    List<RecipeIngredient>? ingredients,
    DateTime? updatedAt,
  }) {
    return NutritionRecipe(
      id: id ?? this.id,
      name: name ?? this.name,
      ingredients: ingredients ?? this.ingredients,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
