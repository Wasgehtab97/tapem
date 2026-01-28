import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/features/nutrition/providers/nutrition_provider.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_recipe.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_entry.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_product.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

class NutritionRecipeListScreen extends ConsumerStatefulWidget {
  final String? meal;
  final bool isSelectionMode;
  final DateTime? date;

  const NutritionRecipeListScreen({
    super.key,
    this.meal,
    this.isSelectionMode = false,
    this.date,
  });

  @override
  ConsumerState<NutritionRecipeListScreen> createState() =>
      _NutritionRecipeListScreenState();
}

class _NutritionRecipeListScreenState
    extends ConsumerState<NutritionRecipeListScreen> {
  late String _selectedMeal;

  @override
  void initState() {
    super.initState();
    _selectedMeal = widget.meal ?? 'breakfast';
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecipes());
  }

  Future<void> _loadRecipes() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.userId;
    if (uid == null || uid.isEmpty) return;
    await ref.read(nutritionProvider).loadRecipes(uid);
  }

  NutritionProduct _productFromRecipe(NutritionRecipe recipe) {
    return NutritionProduct(
      barcode: 'recipe-${recipe.id}',
      name: recipe.name,
      kcalPer100: _computeTotals(recipe, 'kcal'),
      proteinPer100: _computeTotals(recipe, 'protein'),
      carbsPer100: _computeTotals(recipe, 'carbs'),
      fatPer100: _computeTotals(recipe, 'fat'),
      updatedAt: DateTime.now(),
    );
  }

  int _computeTotals(NutritionRecipe recipe, String field) {
    int scale(int per100, double grams) => ((per100 * grams) / 100).round();
    int total = 0;
    for (final ing in recipe.ingredients) {
      switch (field) {
        case 'kcal':
          total += scale(ing.kcalPer100, ing.grams);
          break;
        case 'protein':
          total += scale(ing.proteinPer100, ing.grams);
          break;
        case 'carbs':
          total += scale(ing.carbsPer100, ing.grams);
          break;
        case 'fat':
          total += scale(ing.fatPer100, ing.grams);
          break;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final state = ref.watch(nutritionProvider);
    final recipes = state.recipes;
    final isSelection = widget.isSelectionMode || widget.meal != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelection ? 'Gericht wählen' : 'Meine Gerichte'),
      ),
      body: Column(
        children: [
          // Meal Selector at the top
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs),
            color: Theme.of(context).scaffoldBackgroundColor, // Ensure background matches
            child: NutritionMealPicker(
              selectedMeal: _selectedMeal,
              onChanged: (m) => setState(() => _selectedMeal = m),
            ),
          ),
          Expanded(
            child: recipes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BrandGradientIcon(
                            Icons.restaurant_menu_rounded,
                            size: 80,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          BrandGradientText(
                            'Keine Gerichte',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Erstelle eigene Rezepte und füge sie schnell zu deinen Mahlzeiten hinzu.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.7),
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          PrimaryCTA(
                            label: 'Gericht erstellen',
                            icon: Icons.add_rounded,
                            onPressed: () => Navigator.of(context)
                                .pushNamed(AppRouter.nutritionRecipeEdit),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, 80), // Added bottom padding for FAB
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];

                      // Staggered animation
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(
                            milliseconds: 150 + (index * 50).clamp(0, 300)),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 15 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: NutritionCard(
                          onTap: () {
                              // On Tap -> also Log Mode but maybe with quantity selection?
                              // Or default behaviour?
                              // Usually tapping opens details or adds directly.
                              // Let's make it open details/log mode similar to "Anpassen" but maybe simpler.
                              // User requests: "buttons ... wo ich oben auswählen kann".
                              // If I tap the card, maybe it should just add it? Or open edit?
                              // Existing code opened nutritionEntry.
                              // Let's stick to "Anpassen" for edit/log.
                              // Quick Add is the button.
                              // Let's update onTap to pass selectedMeal too if it goes to Entry.
                            Navigator.of(context).pushNamed(
                              AppRouter.nutritionEntry,
                              arguments: {
                                'name': recipe.name,
                                'meal': _selectedMeal, // Use selected meal
                                'product': _productFromRecipe(recipe),
                                'recipe': recipe,
                                'qty': 100.0,
                                'date': widget.date,
                              },
                            );
                          },
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: BrandGradientText(
                                      recipe.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.3,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, size: 20),
                                    onPressed: () {
                                      Navigator.of(context).pushNamed(
                                        AppRouter.nutritionRecipeEdit,
                                        arguments: {
                                          'recipe': recipe,
                                          'isLogMode': true, // Edit icon in list acts as "Anpassen" too?
                                          // Wait, usually Edit icon is for EDITING the recipe definition (permanent change).
                                          // Log Mode is for logging (one off).
                                          // "Anpassen" button below is for logging with adjustments.
                                          // The Edit icon top right should probably be Real Edit (permanent)?
                                          // But user said "auch beim bearbeiten".
                                          // "und jenachdem welches davon ausgewählt ist dort wird das gericht dann per "schnell add" hinzugefügt bzw auch beim bearbeiten."
                                          // If I edit the recipe permanently, the meal doesn't matter much unless I want to log it after?
                                          // Let's keep Edit icon as Real Edit (Permanent).
                                          // And "Anpassen" button as Log Mode.
                                          // But "Anpassen" button needs to use _selectedMeal.
                                          // Let's check the code below for "Anpassen".
                                          'recipe': recipe,
                                        },
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded,
                                        size: 20, color: Colors.redAccent),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Rezept löschen?'),
                                          content: Text(
                                              'Möchtest du "${recipe.name}" wirklich unwiderruflich löschen?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context)
                                                  .pop(false),
                                              child: const Text('Abbrechen'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context)
                                                  .pop(true),
                                              style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Colors.redAccent),
                                              child: const Text('Löschen'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true && mounted) {
                                        final auth =
                                            ref.read(authControllerProvider);
                                        final uid = auth.userId;
                                        if (uid != null) {
                                          await ref.read(nutritionProvider).deleteRecipe(
                                              uid: uid, id: recipe.id);
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: MacroPill(
                                      label: '',
                                      value:
                                          '${_computeTotals(recipe, 'kcal')} kcal',
                                      color: AppColors.accentTurquoise,
                                      enableGlow: true,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: MacroPill(
                                      label: 'P',
                                      value:
                                          '${_computeTotals(recipe, 'protein')}g',
                                      color: const Color(0xFFE53935),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: MacroPill(
                                      label: 'C',
                                      value:
                                          '${_computeTotals(recipe, 'carbs')}g',
                                      color: AppColors.accentMint,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: MacroPill(
                                      label: 'F',
                                      value:
                                          '${_computeTotals(recipe, 'fat')}g',
                                      color: AppColors.accentAmber,
                                    ),
                                  ),
                                ],
                              ),
                              if (isSelection) ...[
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SecondaryCTA(
                                        label: 'ANPASSEN',
                                        icon: Icons.tune_rounded,
                                        onPressed: () {
                                          Navigator.of(context).pushNamed(
                                            AppRouter.nutritionRecipeEdit,
                                            arguments: {
                                              'recipe': recipe,
                                              'isLogMode': true,
                                              'meal': _selectedMeal, // Use selected meal
                                              'date': widget.date,
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          final auth = ref.read(authControllerProvider);
                                          final uid = auth.userId;
                                          if (uid == null || uid.isEmpty) return;

                                          // Use the selected meal from the top picker
                                          // No need to ask again.
                                          
                                          final kcal =
                                              _computeTotals(recipe, 'kcal');
                                          final protein =
                                              _computeTotals(recipe, 'protein');
                                          final carbs =
                                              _computeTotals(recipe, 'carbs');
                                          final fat =
                                              _computeTotals(recipe, 'fat');

                                          await ref
                                              .read(nutritionProvider)
                                              .addEntry(
                                                uid: uid,
                                                date: widget.date ??
                                                    DateTime.now(),
                                                entry: NutritionEntry(
                                                  name: recipe.name,
                                                  meal: _selectedMeal, // Use selected meal
                                                  kcal: kcal,
                                                  protein: protein,
                                                  carbs: carbs,
                                                  fat: fat,
                                                  qty: 100, // Normalized
                                                ),
                                              );
                                          if (mounted) {
                                            Navigator.of(context).pop();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                                  .extension<AppBrandTheme>()
                                                  ?.outline ??
                                              Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          'SCHNELL ADD',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: recipes.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                            .extension<AppBrandTheme>()
                            ?.outline
                            .withOpacity(0.3) ??
                        Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRouter.nutritionRecipeEdit),
                tooltip: 'Gericht erstellen',
                child: const BrandGradientIcon(Icons.add_rounded, size: 28),
              ),
            )
          : null,
    );
  }
}
