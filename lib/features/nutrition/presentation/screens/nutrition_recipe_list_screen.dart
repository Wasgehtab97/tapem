import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
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
    final isSelection = widget.isSelectionMode || widget.meal != null;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelection)
              ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Anpassen'),
                onTap: () => Navigator.of(ctx).pop('adjust'),
              ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Bearbeiten'),
              onTap: () => Navigator.of(ctx).pop('edit'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              title: const Text('Löschen'),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    if (action == 'adjust') {
      Navigator.of(context).pushNamed(
        AppRouter.nutritionRecipeEdit,
        arguments: {
          'recipe': recipe,
          'isLogMode': true,
          'meal': _selectedMeal,
          'date': widget.date,
        },
      );
      return;
    }
    if (action == 'edit') {
      Navigator.of(
        context,
      ).pushNamed(AppRouter.nutritionRecipeEdit, arguments: {'recipe': recipe});
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

  Future<double?> _pickQuickAddFactor({
    required NutritionRecipe recipe,
    required NutritionTotals totals,
  }) async {
    const presets = <double>[0.5, 0.75, 1.0, 1.5, 2.0];
    double selected = 1.0;
    final factorCtrl = TextEditingController(text: '1');

    String formatFactor(double value) {
      if (value == value.roundToDouble()) return value.toInt().toString();
      return value.toStringAsFixed(
        value * 10 == (value * 10).roundToDouble() ? 1 : 2,
      );
    }

    int scaled(int value, double factor) => (value * factor).round();

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final previewFactor = selected;
            final scaledKcal = scaled(totals.kcal, previewFactor);
            final scaledP = scaled(totals.protein, previewFactor);
            final scaledC = scaled(totals.carbs, previewFactor);
            final scaledF = scaled(totals.fat, previewFactor);
            return AlertDialog(
              title: const Text('Schnell Add Faktor'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final preset in presets)
                        ChoiceChip(
                          label: Text('x${formatFactor(preset)}'),
                          selected: (selected - preset).abs() < 0.0001,
                          onSelected: (_) {
                            setDialogState(() {
                              selected = preset;
                              factorCtrl.text = formatFactor(preset);
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: factorCtrl,
                    autofocus: false,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Faktor',
                      hintText: 'z.B. 0,5 oder 2',
                    ),
                    onChanged: (raw) {
                      final parsed = double.tryParse(raw.replaceAll(',', '.'));
                      if (parsed != null && parsed > 0) {
                        setDialogState(
                          () => selected = parsed.clamp(0.1, 10.0),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vorschau: $scaledKcal kcal · ${scaledP}P · ${scaledC}C · ${scaledF}F',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: () {
                    final parsed = double.tryParse(
                      factorCtrl.text.trim().replaceAll(',', '.'),
                    );
                    final factor = ((parsed ?? selected).clamp(
                      0.1,
                      10.0,
                    )).toDouble();
                    Navigator.of(dialogContext).pop(factor);
                  },
                  child: const Text('Hinzufügen'),
                ),
              ],
            );
          },
        );
      },
    );

    factorCtrl.dispose();
    return result;
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
                                _RecipeActionButton(
                                  label: 'Schnell Add',
                                  icon: Icons.add_rounded,
                                  emphasized: true,
                                  onTap: () async {
                                    final factor = await _pickQuickAddFactor(
                                      recipe: recipe,
                                      totals: totals,
                                    );
                                    if (factor == null) return;
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
                                              widget.date ?? state.selectedDate,
                                          recipe: recipe,
                                          meal: _selectedMeal,
                                          factor: factor,
                                        );
                                    if (mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
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
              onPressed: () => Navigator.of(
                context,
              ).pushNamed(AppRouter.nutritionRecipeEdit),
              tooltip: 'Gericht erstellen',
              child: const BrandGradientIcon(Icons.add_rounded, size: 24),
            )
          : null,
    );
  }
}

class _RecipeActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool emphasized;
  final VoidCallback onTap;

  const _RecipeActionButton({
    required this.label,
    required this.icon,
    required this.emphasized,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = nutritionBrandAccentColor(context);
    final borderColor = emphasized
        ? accent.withOpacity(0.45)
        : Colors.white.withOpacity(0.10);
    final background = emphasized
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.withOpacity(0.24), accent.withOpacity(0.10)],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor.withOpacity(0.40),
              theme.scaffoldBackgroundColor.withOpacity(0.26),
            ],
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: background,
            border: Border.all(color: borderColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: emphasized
                    ? accent
                    : theme.colorScheme.onSurface.withOpacity(0.88),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: emphasized
                        ? accent
                        : theme.colorScheme.onSurface.withOpacity(0.9),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
