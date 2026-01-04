import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_product.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_recipe.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/features/nutrition/providers/nutrition_provider.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_totals.dart';
import 'package:tapem/features/nutrition/providers/nutrition_product_provider.dart';

class NutritionRecipeEditScreen extends ConsumerStatefulWidget {
  final NutritionRecipe? recipe;
  const NutritionRecipeEditScreen({super.key, this.recipe});

  @override
  ConsumerState<NutritionRecipeEditScreen> createState() =>
      _NutritionRecipeEditScreenState();
}

class _NutritionRecipeEditScreenState
    extends ConsumerState<NutritionRecipeEditScreen> {
  late final TextEditingController _nameController;
  final List<RecipeIngredient> _ingredients = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipe?.name ?? '');
    _ingredients.addAll(widget.recipe?.ingredients ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  NutritionTotals _sum() {
    int scale(int per100, double grams) => ((per100 * grams) / 100).round();
    int kcal = 0, protein = 0, carbs = 0, fat = 0;
    for (final ing in _ingredients) {
      kcal += scale(ing.kcalPer100, ing.grams);
      protein += scale(ing.proteinPer100, ing.grams);
      carbs += scale(ing.carbsPer100, ing.grams);
      fat += scale(ing.fatPer100, ing.grams);
    }
    return NutritionTotals(kcal: kcal, protein: protein, carbs: carbs, fat: fat);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _ingredients.isEmpty) return;
    final uid = ref.read(authControllerProvider).userId;
    if (uid == null || uid.isEmpty) return;
    setState(() => _saving = true);
    final recipe = NutritionRecipe(
      id: widget.recipe?.id ?? '',
      name: name,
      ingredients: List.of(_ingredients),
      updatedAt: DateTime.now(),
    );
    try {
      await ref.read(nutritionProvider).saveRecipe(uid: uid, recipe: recipe);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addManualIngredient() async {
    final nameCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController();
    final kcalCtrl = TextEditingController();
    final pCtrl = TextEditingController();
    final cCtrl = TextEditingController();
    final fCtrl = TextEditingController();
    final gramsCtrl = TextEditingController(text: '100');
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Zutat hinzufügen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: barcodeCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Barcode (optional)'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: kcalCtrl,
                        decoration:
                            const InputDecoration(labelText: 'kcal /100g'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: gramsCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Gramm'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Protein /100g'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: cCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Carbs /100g'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: fCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Fett /100g'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final ing = RecipeIngredient(
                  name: name,
                  barcode: barcodeCtrl.text.trim().isEmpty
                      ? null
                      : barcodeCtrl.text.trim(),
                  kcalPer100: int.tryParse(kcalCtrl.text) ?? 0,
                  proteinPer100: int.tryParse(pCtrl.text) ?? 0,
                  carbsPer100: int.tryParse(cCtrl.text) ?? 0,
                  fatPer100: int.tryParse(fCtrl.text) ?? 0,
                  grams: double.tryParse(gramsCtrl.text) ?? 100,
                );
                Navigator.of(ctx).pop(ing);
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        );
      },
    ).then((value) {
      if (value is RecipeIngredient) {
        setState(() => _ingredients.add(value));
      }
    });
  }

  Future<void> _addFromProduct() async {
    final result = await Navigator.of(context).pushNamed(
      AppRouter.nutritionSearch,
      arguments: {'query': ''},
    );
    if (result is! NutritionProduct) return;
    final gramsCtrl = TextEditingController(text: '100');
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(result.name),
          content: TextField(
            controller: gramsCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Gramm'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                final grams = double.tryParse(gramsCtrl.text) ?? 100;
                final ing = RecipeIngredient(
                  name: result.name,
                  barcode: result.barcode,
                  kcalPer100: result.kcalPer100,
                  proteinPer100: result.proteinPer100,
                  carbsPer100: result.carbsPer100,
                  fatPer100: result.fatPer100,
                  grams: grams,
                );
                Navigator.of(ctx).pop(ing);
              },
              child: const Text('Übernehmen'),
            ),
          ],
        );
      },
    ).then((value) {
      if (value is RecipeIngredient) {
        setState(() => _ingredients.add(value));
      }
    });
  }

  Future<void> _addFromScan() async {
    final barcode = await Navigator.of(context).pushNamed(
      AppRouter.nutritionScan,
      arguments: {'returnBarcode': true},
    );
    if (barcode is! String || barcode.isEmpty) return;
    final service = ref.read(nutritionProductServiceProvider);
    final product = await service.getByBarcode(barcode);
    if (product == null) return;
    final gramsCtrl = TextEditingController(text: '100');
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(product.name),
          content: TextField(
            controller: gramsCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Gramm'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                final grams = double.tryParse(gramsCtrl.text) ?? 100;
                final ing = RecipeIngredient(
                  name: product.name,
                  barcode: product.barcode,
                  kcalPer100: product.kcalPer100,
                  proteinPer100: product.proteinPer100,
                  carbsPer100: product.carbsPer100,
                  fatPer100: product.fatPer100,
                  grams: grams,
                );
                Navigator.of(ctx).pop(ing);
              },
              child: const Text('Übernehmen'),
            ),
          ],
        );
      },
    ).then((value) {
      if (value is RecipeIngredient) {
        setState(() => _ingredients.add(value));
      }
    });
  }

  Future<void> _editGrams(RecipeIngredient ing) async {
    final gramsCtrl = TextEditingController(
      text: ing.grams.toStringAsFixed(0),
    );
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(ing.name),
          content: TextField(
            controller: gramsCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Gramm'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(double.tryParse(gramsCtrl.text) ?? ing.grams);
              },
              child: const Text('Übernehmen'),
            ),
          ],
        );
      },
    ).then((value) {
      if (value is double) {
        setState(() {
          final idx = _ingredients.indexOf(ing);
          if (idx >= 0) {
            _ingredients[idx] = RecipeIngredient(
              name: ing.name,
              barcode: ing.barcode,
              kcalPer100: ing.kcalPer100,
              proteinPer100: ing.proteinPer100,
              carbsPer100: ing.carbsPer100,
              fatPer100: ing.fatPer100,
              grams: value,
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sum = _sum();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? 'Gericht erstellen' : 'Gericht bearbeiten'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.lg,
          ),
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name des Gerichts'),
            ),
            const SizedBox(height: AppSpacing.sm),
            NutritionCard(
              child: Wrap(
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
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addFromProduct,
                    icon: const Icon(Icons.search),
                    label: const Text('Produkt suchen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      foregroundColor: theme.colorScheme.onSurface,
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addFromScan,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Barcode scannen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      foregroundColor: theme.colorScheme.onSurface,
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addManualIngredient,
                    icon: const Icon(Icons.add),
                    label: const Text('Manuell'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      foregroundColor: theme.colorScheme.onSurface,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_ingredients.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  'Keine Zutaten hinzugefügt.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              ..._ingredients.map((ing) {
                return NutritionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ing.name,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                setState(() => _ingredients.remove(ing)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          MacroPill(
                            label: 'kcal',
                            value:
                                '${((ing.kcalPer100 * ing.grams) / 100).round()}',
                            color: Colors.blueAccent,
                          ),
                          MacroPill(
                            label: 'P',
                            value:
                                '${((ing.proteinPer100 * ing.grams) / 100).round()} g',
                            color: Colors.redAccent,
                          ),
                          MacroPill(
                            label: 'C',
                            value:
                                '${((ing.carbsPer100 * ing.grams) / 100).round()} g',
                            color: Colors.greenAccent.shade400,
                          ),
                          MacroPill(
                            label: 'F',
                            value:
                                '${((ing.fatPer100 * ing.grams) / 100).round()} g',
                            color: Colors.amber.shade700,
                          ),
                          MacroPill(
                            label: 'Gramm',
                            value: ing.grams.toStringAsFixed(0),
                            color: theme.colorScheme.primary,
                            onTap: () => _editGrams(ing),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: AppSpacing.lg),
            PrimaryCTA(
              label: 'Gericht speichern',
              icon: Icons.save,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
