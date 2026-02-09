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
import 'package:tapem/features/nutrition/domain/utils/nutrition_recipe_math.dart';
import 'package:tapem/features/nutrition/providers/nutrition_product_provider.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

class NutritionRecipeEditScreen extends ConsumerStatefulWidget {
  final NutritionRecipe? recipe;
  final bool isLogMode;
  final String? logMeal;
  final DateTime? logDate;

  const NutritionRecipeEditScreen({
    super.key,
    this.recipe,
    this.isLogMode = false,
    this.logMeal,
    this.logDate,
  });

  @override
  ConsumerState<NutritionRecipeEditScreen> createState() =>
      _NutritionRecipeEditScreenState();
}

class _NutritionRecipeEditScreenState
    extends ConsumerState<NutritionRecipeEditScreen> {
  late final TextEditingController _nameController;
  final List<RecipeIngredient> _ingredients = [];
  bool _saving = false;
  late String _selectedMeal;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipe?.name ?? '');
    _ingredients.addAll(widget.recipe?.ingredients ?? []);
    _selectedMeal = widget.logMeal ?? 'breakfast';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  RecipeNutritionSummary _summary() {
    return summarizeRecipeIngredients(_ingredients);
  }

  NutritionTotals _sum() {
    return _summary().totals;
  }

  String _formatGrams(double grams) {
    if (grams % 1 == 0) return grams.toInt().toString();
    return grams.toStringAsFixed(1);
  }

  double _parseGramsInput(String raw, {required double fallback}) {
    final parsed = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return fallback;
    return parsed;
  }

  Future<void> _saveRecipe({required bool closeAfterSave}) async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _ingredients.isEmpty) return;
    final uid = ref.read(authControllerProvider).userId;
    if (uid == null || uid.isEmpty) return;
    setState(() => _saving = true);

    try {
      final recipe = NutritionRecipe(
        id: widget.recipe?.id ?? '',
        name: name,
        ingredients: List.of(_ingredients),
        updatedAt: DateTime.now(),
      );
      await ref.read(nutritionProvider).saveRecipe(uid: uid, recipe: recipe);
      if (!mounted) return;
      if (closeAfterSave) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gericht gespeichert.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveRecipeAndClose() {
    return _saveRecipe(closeAfterSave: true);
  }

  Future<void> _saveRecipeOnly() {
    return _saveRecipe(closeAfterSave: false);
  }

  Future<void> _addToDay() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _ingredients.isEmpty) return;
    final uid = ref.read(authControllerProvider).userId;
    if (uid == null || uid.isEmpty) return;
    setState(() => _saving = true);
    try {
      final recipeId = (widget.recipe?.id ?? '').trim();
      final draftRecipe = NutritionRecipe(
        id: recipeId,
        name: name,
        ingredients: List.of(_ingredients),
        updatedAt: DateTime.now(),
      );
      await ref
          .read(nutritionProvider)
          .addRecipeToMeal(
            uid: uid,
            date: widget.logDate ?? ref.read(nutritionProvider).selectedDate,
            recipe: draftRecipe,
            meal: _selectedMeal,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gericht löschen?'),
        content: const Text(
          'Möchtest du dieses Gericht wirklich unwiderruflich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final uid = ref.read(authControllerProvider).userId;
    if (uid == null || uid.isEmpty || widget.recipe == null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(nutritionProvider)
          .deleteRecipe(uid: uid, id: widget.recipe!.id);
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
                  decoration: const InputDecoration(
                    labelText: 'Barcode (optional)',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: kcalCtrl,
                        decoration: const InputDecoration(
                          labelText: 'kcal /100g',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: gramsCtrl,
                        decoration: const InputDecoration(labelText: 'Gramm'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Protein /100g',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: cCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Carbs /100g',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: fCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Fett /100g',
                        ),
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
                  grams: _parseGramsInput(gramsCtrl.text, fallback: 100),
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
    final result = await Navigator.of(
      context,
    ).pushNamed(AppRouter.nutritionSearch, arguments: {'query': ''});
    if (result is! NutritionProduct) return;
    final gramsCtrl = TextEditingController(text: '100');
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(result.name),
          content: TextField(
            controller: gramsCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Gramm'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                final grams = _parseGramsInput(gramsCtrl.text, fallback: 100);
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
    final barcode = await Navigator.of(
      context,
    ).pushNamed(AppRouter.nutritionScan, arguments: {'returnBarcode': true});
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Gramm'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                final grams = _parseGramsInput(gramsCtrl.text, fallback: 100);
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
    final gramsCtrl = TextEditingController(text: _formatGrams(ing.grams));
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(ing.name),
          content: TextField(
            controller: gramsCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Gramm'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  ctx,
                ).pop(_parseGramsInput(gramsCtrl.text, fallback: ing.grams));
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

    // Title logic
    String title = 'Gericht erstellen';
    if (widget.isLogMode) {
      title = 'Gericht eintragen';
    } else if (widget.recipe != null) {
      title = 'Gericht bearbeiten';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // Hide delete if in Log Mode
          if (widget.recipe != null && !widget.isLogMode)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              tooltip: 'Gericht löschen',
            ),
          if (widget.isLogMode)
            TextButton.icon(
              onPressed: _saving ? null : _saveRecipeOnly,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Speichern'),
            )
          else
            IconButton(
              onPressed: _saving ? null : _saveRecipeAndClose,
              icon: const Icon(Icons.save_rounded),
              tooltip: 'Gericht speichern',
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
            if (widget.isLogMode)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: NutritionMealPicker(
                  selectedMeal: _selectedMeal,
                  onChanged: (m) => setState(() => _selectedMeal = m),
                ),
              ),
            BrandInteractiveCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.3),
              enableScaleAnimation: false,
              showShadow: false,
              child: TextField(
                controller: _nameController,
                style: theme.textTheme.titleMedium,
                decoration: const InputDecoration(
                  labelText: 'Name des Gerichts',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            NutritionCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              background: theme.colorScheme.surfaceVariant.withOpacity(0.15),
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
            const SizedBox(height: AppSpacing.sm),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MiniActionButton(
                    icon: Icons.search_rounded,
                    label: 'Suchen',
                    onTap: _addFromProduct,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniActionButton(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scannen',
                    onTap: _addFromScan,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniActionButton(
                    icon: Icons.add_rounded,
                    label: 'Manuell',
                    onTap: _addManualIngredient,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const Icon(Icons.restaurant_menu_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Zutaten',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_ingredients.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  'Noch keine Zutaten hinzugefügt.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              )
            else
              ..._ingredients.map((ing) {
                final brand = theme.extension<AppBrandTheme>();
                final brandColor =
                    brand?.outline ?? theme.colorScheme.secondary;

                return BrandInteractiveCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  backgroundColor: theme.scaffoldBackgroundColor.withOpacity(
                    0.35,
                  ),
                  showShadow: false,
                  enableScaleAnimation: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ing.name,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (ing.barcode != null)
                                  Text(
                                    ing.barcode!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.4),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.more_horiz_rounded,
                              size: 20,
                            ),
                            onPressed: () async {
                              final action = await showModalBottomSheet<String>(
                                context: context,
                                showDragHandle: true,
                                builder: (ctx) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.edit_rounded),
                                        title: const Text('Menge bearbeiten'),
                                        onTap: () =>
                                            Navigator.of(ctx).pop('edit'),
                                      ),
                                      ListTile(
                                        leading: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.redAccent,
                                        ),
                                        title: const Text('Zutat entfernen'),
                                        onTap: () =>
                                            Navigator.of(ctx).pop('delete'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                              if (!mounted || action == null) return;
                              if (action == 'edit') {
                                await _editGrams(ing);
                                return;
                              }
                              setState(() => _ingredients.remove(ing));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _SmallMacroPill(
                                  label: 'kcal',
                                  value:
                                      '${((ing.kcalPer100 * ing.grams) / 100).round()}',
                                  color: Colors.blueAccent,
                                ),
                                _SmallMacroPill(
                                  label: 'P',
                                  value:
                                      '${((ing.proteinPer100 * ing.grams) / 100).round()}g',
                                  color: Colors.redAccent,
                                ),
                                _SmallMacroPill(
                                  label: 'C',
                                  value:
                                      '${((ing.carbsPer100 * ing.grams) / 100).round()}g',
                                  color: Colors.greenAccent.shade400,
                                ),
                                _SmallMacroPill(
                                  label: 'F',
                                  value:
                                      '${((ing.fatPer100 * ing.grams) / 100).round()}g',
                                  color: Colors.amber.shade700,
                                ),
                                _SmallMacroPill(
                                  label: 'g',
                                  value: _formatGrams(ing.grams),
                                  color: brandColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: AppSpacing.lg),
            BrandPrimaryButton(
              onPressed: _saving
                  ? null
                  : (widget.isLogMode ? _addToDay : _saveRecipeAndClose),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_saving)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    Icon(
                      widget.isLogMode
                          ? Icons.check_rounded
                          : Icons.save_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isLogMode ? 'Hinzufügen' : 'Gericht speichern',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: brandColor.withOpacity(0.16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: brandColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallMacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SmallMacroPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = nutritionBrandAccentColor(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
