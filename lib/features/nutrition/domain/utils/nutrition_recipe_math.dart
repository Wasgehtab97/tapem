import 'package:tapem/features/nutrition/domain/models/nutrition_entry.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_recipe.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_totals.dart';

class RecipeNutritionSummary {
  final NutritionTotals totals;
  final double grams;

  const RecipeNutritionSummary({required this.totals, required this.grams});

  int get kcalPer100 => _per100(totals.kcal);
  int get proteinPer100 => _per100(totals.protein);
  int get carbsPer100 => _per100(totals.carbs);
  int get fatPer100 => _per100(totals.fat);

  int _per100(int value) {
    if (grams <= 0) return 0;
    return ((value * 100) / grams).round();
  }
}

RecipeNutritionSummary summarizeRecipeIngredients(
  Iterable<RecipeIngredient> ingredients, {
  double factor = 1.0,
}) {
  final safeFactor = factor <= 0 ? 1.0 : factor;
  int scale(int per100, double grams) => ((per100 * grams) / 100).round();

  int kcal = 0;
  int protein = 0;
  int carbs = 0;
  int fat = 0;
  double grams = 0;

  for (final ingredient in ingredients) {
    final scaledGrams = (ingredient.grams * safeFactor)
        .clamp(0, 100000)
        .toDouble();
    grams += scaledGrams;
    kcal += scale(ingredient.kcalPer100, scaledGrams);
    protein += scale(ingredient.proteinPer100, scaledGrams);
    carbs += scale(ingredient.carbsPer100, scaledGrams);
    fat += scale(ingredient.fatPer100, scaledGrams);
  }

  return RecipeNutritionSummary(
    totals: NutritionTotals(
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
    ),
    grams: grams,
  );
}

List<NutritionEntry> buildRecipeIngredientEntries({
  required String recipeName,
  required String meal,
  required Iterable<RecipeIngredient> ingredients,
  double factor = 1.0,
  String? recipeId,
}) {
  final safeFactor = factor <= 0 ? 1.0 : factor;
  int scale(int per100, double grams) => ((per100 * grams) / 100).round();
  final entries = <NutritionEntry>[];

  for (final ingredient in ingredients) {
    final grams = (ingredient.grams * safeFactor).clamp(0, 100000).toDouble();
    if (grams <= 0) continue;
    final ingredientName = ingredient.name.trim();

    entries.add(
      NutritionEntry(
        name: ingredientName.isEmpty ? recipeName : ingredientName,
        meal: meal,
        kcal: scale(ingredient.kcalPer100, grams),
        protein: scale(ingredient.proteinPer100, grams),
        carbs: scale(ingredient.carbsPer100, grams),
        fat: scale(ingredient.fatPer100, grams),
        barcode: ingredient.barcode,
        recipeId: recipeId,
        qty: grams,
      ),
    );
  }

  return entries;
}
