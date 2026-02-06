import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/features/nutrition/providers/nutrition_provider.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_recipe.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_product.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_totals.dart';
import 'package:tapem/features/nutrition/domain/utils/nutrition_recipe_math.dart';
import 'package:tapem/core/providers/auth_providers.dart';
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
    final summary = summarizeRecipeIngredients(recipe.ingredients);
    int per100(int total) {
      if (summary.grams <= 0) return 0;
      return ((total * 100) / summary.grams).round();
    }

    return NutritionProduct(
      barcode: 'recipe-${recipe.id}',
      name: recipe.name,
      kcalPer100: per100(summary.totals.kcal),
      proteinPer100: per100(summary.totals.protein),
      carbsPer100: per100(summary.totals.carbs),
      fatPer100: per100(summary.totals.fat),
      updatedAt: DateTime.now(),
    );
  }

  NutritionTotals _computeTotals(NutritionRecipe recipe) {
    return summarizeRecipeIngredients(recipe.ingredients).totals;
  }

  double _totalGrams(NutritionRecipe recipe) {
    return summarizeRecipeIngredients(recipe.ingredients).grams;
  }

  Future<void> _openRecipeActions(NutritionRecipe recipe) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Bearbeiten'),
              onTap: () => Navigator.of(ctx).pop('edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Löschen'),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    if (action == 'edit') {
      Navigator.of(context).pushNamed(
        AppRouter.nutritionRecipeEdit,
        arguments: {'recipe': recipe},
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rezept löschen?'),
        content: Text(
          'Möchtest du "${recipe.name}" wirklich unwiderruflich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final auth = ref.read(authControllerProvider);
      final uid = auth.userId;
      if (uid != null) {
        await ref.read(nutritionProvider).deleteRecipe(uid: uid, id: recipe.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            color: Theme.of(
              context,
            ).scaffoldBackgroundColor, // Ensure background matches
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Erstelle eigene Rezepte und füge sie schnell zu deinen Mahlzeiten hinzu.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
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
                            onPressed: () => Navigator.of(
                              context,
                            ).pushNamed(AppRouter.nutritionRecipeEdit),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.xs,
                      AppSpacing.sm,
                      80,
                    ), // Added bottom padding for FAB
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      final totals = _computeTotals(recipe);
                      final totalGrams = _totalGrams(recipe);

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(
                          milliseconds: 120 + (index * 36).clamp(0, 220),
                        ),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 8 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: NutritionCard(
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              AppRouter.nutritionEntry,
                              arguments: {
                                'name': recipe.name,
                                'meal': _selectedMeal,
                                'product': _productFromRecipe(recipe),
                                'recipe': recipe,
                                'qty': totalGrams > 0 ? totalGrams : 100.0,
                                'date': widget.date ?? state.selectedDate,
                              },
                            );
                          },
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      recipe.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.more_horiz_rounded,
                                      size: 20,
                                    ),
                                    onPressed: () => _openRecipeActions(recipe),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: MacroPill(
                                      label: '',
                                      value: '${totals.kcal} kcal',
                                      color: AppColors.accentTurquoise,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: MacroPill(
                                      label: 'P',
                                      value: '${totals.protein}g',
                                      color: const Color(0xFFE53935),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: MacroPill(
                                      label: 'C',
                                      value: '${totals.carbs}g',
                                      color: AppColors.accentMint,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: MacroPill(
                                      label: 'F',
                                      value: '${totals.fat}g',
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
                                              'meal': _selectedMeal,
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
                                          final auth = ref.read(
                                            authControllerProvider,
                                          );
                                          final uid = auth.userId;
                                          if (uid == null || uid.isEmpty) {
                                            return;
                                          }

                                          await ref
                                              .read(nutritionProvider)
                                              .addRecipeToMeal(
                                                uid: uid,
                                                date:
                                                    widget.date ??
                                                    state.selectedDate,
                                                recipe: recipe,
                                                meal: _selectedMeal,
                                              );
                                          if (mounted) {
                                            Navigator.of(context).pop();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Theme.of(context)
                                                  .extension<AppBrandTheme>()
                                                  ?.outline ??
                                              Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          'SCHNELL ADD',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
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
          ? FloatingActionButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.nutritionRecipeEdit),
              tooltip: 'Gericht erstellen',
              child: const BrandGradientIcon(Icons.add_rounded, size: 24),
            )
          : null,
    );
  }
}
