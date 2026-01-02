import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_recipe.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_totals.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/features/nutrition/providers/nutrition_provider.dart';

class NutritionRecipeListScreen extends ConsumerStatefulWidget {
  const NutritionRecipeListScreen({super.key});

  @override
  ConsumerState<NutritionRecipeListScreen> createState() =>
      _NutritionRecipeListScreenState();
}

class _NutritionRecipeListScreenState
    extends ConsumerState<NutritionRecipeListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final uid = ref.read(authControllerProvider).userId;
    if (uid == null || uid.isEmpty) return;
    await ref.read(nutritionProvider).loadRecipes(uid);
    await ref.read(nutritionProvider).loadDay(uid, DateTime.now());
  }

  NutritionTotals _sum(NutritionRecipe recipe) {
    int scale(int per100, double grams) => ((per100 * grams) / 100).round();
    int kcal = 0, protein = 0, carbs = 0, fat = 0;
    for (final ing in recipe.ingredients) {
      kcal += scale(ing.kcalPer100, ing.grams);
      protein += scale(ing.proteinPer100, ing.grams);
      carbs += scale(ing.carbsPer100, ing.grams);
      fat += scale(ing.fatPer100, ing.grams);
    }
    return NutritionTotals(kcal: kcal, protein: protein, carbs: carbs, fat: fat);
  }

  Future<void> _addToMeal(NutritionRecipe recipe) async {
    final uid = ref.read(authControllerProvider).userId;
    if (uid == null || uid.isEmpty) return;
    final loc = Localizations.localeOf(context).languageCode.startsWith('de');
    String meal = 'breakfast';
    double factor = 1.0;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc ? 'Gericht hinzufügen' : 'Add recipe',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: meal,
                      decoration: const InputDecoration(labelText: 'Mahlzeit'),
                      items: const [
                        DropdownMenuItem(value: 'breakfast', child: Text('Frühstück')),
                        DropdownMenuItem(value: 'lunch', child: Text('Mittagessen')),
                        DropdownMenuItem(value: 'dinner', child: Text('Abendessen')),
                        DropdownMenuItem(value: 'snack', child: Text('Snack')),
                      ],
                      onChanged: (v) => meal = v ?? 'breakfast',
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      initialValue: '1.0',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Faktor'),
                      onChanged: (v) => factor = double.tryParse(v.replaceAll(',', '.')) ?? 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(ctx).pop(true),
                icon: const Icon(Icons.check),
                label: Text(loc ? 'Übernehmen' : 'Apply'),
              ),
            ],
          ),
        );
      },
    ).then((ok) async {
      if (ok != true) return;
      final date = ref.read(nutritionProvider).selectedDate;
      await ref.read(nutritionProvider).addRecipeToMeal(
            uid: uid,
            date: date,
            recipe: recipe,
            meal: meal,
            factor: factor,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(nutritionProvider).isLoadingRecipes;
    final recipes = ref.watch(nutritionProvider).recipes;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerichte'),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRouter.nutritionRecipeEdit),
            icon: const Icon(Icons.add),
            tooltip: 'Neu',
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.lg,
                ),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  final sum = _sum(recipe);
                  return NutritionCard(
                    neutral: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                recipe.name,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => Navigator.of(context).pushNamed(
                                AppRouter.nutritionRecipeEdit,
                                arguments: {'recipe': recipe},
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final uid =
                                    ref.read(authControllerProvider).userId;
                                if (uid == null) return;
                                await ref
                                    .read(nutritionProvider)
                                    .deleteRecipe(uid: uid, id: recipe.id);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            MacroPill(
                              label: 'Kcal',
                              value: '${sum.kcal}',
                              color: Colors.blueAccent,
                            ),
                            MacroPill(
                              label: 'P',
                              value: '${sum.protein} g',
                              color: Colors.redAccent,
                            ),
                            MacroPill(
                              label: 'C',
                              value: '${sum.carbs} g',
                              color: Colors.greenAccent.shade400,
                            ),
                            MacroPill(
                              label: 'F',
                              value: '${sum.fat} g',
                              color: Colors.amber.shade700,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _addToMeal(recipe),
                          icon: const Icon(Icons.restaurant_menu),
                          label: const Text('Zu Mahlzeit hinzufügen'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                theme.colorScheme.surfaceVariant.withOpacity(0.5),
                            foregroundColor: theme.colorScheme.onSurface,
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
