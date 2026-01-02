import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_entry.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_product.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/features/nutrition/providers/nutrition_product_provider.dart';
import 'package:tapem/features/nutrition/providers/nutrition_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class NutritionProductScreen extends ConsumerStatefulWidget {
  final String barcode;
  final String initialMeal;
  const NutritionProductScreen({
    super.key,
    required this.barcode,
    this.initialMeal = 'breakfast',
  });

  @override
  ConsumerState<NutritionProductScreen> createState() =>
      _NutritionProductScreenState();
}

class _NutritionProductScreenState
    extends ConsumerState<NutritionProductScreen> {
  NutritionProduct? _product;
  bool _loading = false;
  bool _saving = false;
  String _meal = 'breakfast';
  late final TextEditingController _gramsController;
  late final TextEditingController _nameController;
  late final TextEditingController _kcalController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;

  @override
  void initState() {
    super.initState();
    _gramsController = TextEditingController(text: '100');
    _nameController = TextEditingController();
    _kcalController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
    _meal = widget.initialMeal;
    _gramsController.addListener(_onGramsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
  }

  @override
  void dispose() {
    _gramsController.removeListener(_onGramsChanged);
    _gramsController.dispose();
    _nameController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _onGramsChanged() {
    // keep UI in sync with gram edits
    if (mounted) setState(() {});
  }

  Future<void> _loadProduct() async {
    if (widget.barcode.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final service = ref.read(nutritionProductServiceProvider);
      final product = await service.getByBarcode(widget.barcode);
      if (!mounted) return;
      setState(() => _product = product);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  int _scaledInt(int per100, double grams) {
    return ((per100 * grams) / 100).round();
  }

  int _parseInt(String raw) {
    final sanitized = raw.trim();
    if (sanitized.isEmpty) return 0;
    return int.tryParse(sanitized) ?? 0;
  }

  double _grams() {
    final raw = _gramsController.text.trim().replaceAll(',', '.');
    final val = double.tryParse(raw);
    return val == null || val <= 0 ? 100.0 : val;
  }

  bool _isValidBarcode(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return false;
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) return false;
    return trimmed.length == 8 ||
        trimmed.length == 12 ||
        trimmed.length == 13 ||
        trimmed.length == 14;
  }

  Future<void> _saveEntry() async {
    if (_product == null) return;
    final auth = ref.read(authControllerProvider);
    final uid = auth.userId;
    if (uid == null || uid.isEmpty) return;
    setState(() => _saving = true);
    final grams = _grams();
    final entry = NutritionEntry(
      name: _product!.name,
      kcal: _scaledInt(_product!.kcalPer100, grams),
      protein: _scaledInt(_product!.proteinPer100, grams),
      carbs: _scaledInt(_product!.carbsPer100, grams),
      fat: _scaledInt(_product!.fatPer100, grams),
      meal: _meal,
      barcode: _product!.barcode,
      qty: grams,
    );
    try {
      final date = ref.read(nutritionProvider).selectedDate;
      await ref.read(nutritionProvider).addEntry(
            uid: uid,
            date: date,
            entry: entry,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nutritionEntrySaved)),
      );
      bool popped = false;
      Navigator.of(context).popUntil((route) {
        final match = route.settings.name == AppRouter.nutritionEntry;
        if (!popped && match) popped = true;
        return match;
      });
      if (!popped && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nutritionEntrySaveError)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _mealLabel(String meal) {
    switch (meal) {
      case 'lunch':
        return 'Mittagessen';
      case 'dinner':
        return 'Abendessen';
      case 'snack':
        return 'Snack';
      default:
        return 'Frühstück';
    }
  }

  Future<void> _pickMeal() async {
    final meals = [
      ('breakfast', 'Frühstück'),
      ('lunch', 'Mittagessen'),
      ('dinner', 'Abendessen'),
      ('snack', 'Snack'),
    ];
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              for (final meal in meals)
                ListTile(
                  title: Text(meal.$2),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(ctx).pop(meal.$1),
                ),
            ],
          ),
        );
      },
    );
    if (choice != null && mounted) {
      setState(() => _meal = choice);
    }
  }

  Future<void> _saveManualProduct() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.userId;
    if (uid == null || uid.isEmpty) return;
    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        setState(() => _saving = false);
        return;
      }
      final product = NutritionProduct(
        barcode: widget.barcode,
        name: name,
        kcalPer100: _parseInt(_kcalController.text),
        proteinPer100: _parseInt(_proteinController.text),
        carbsPer100: _parseInt(_carbsController.text),
        fatPer100: _parseInt(_fatController.text),
        updatedAt: DateTime.now(),
      );
      final service = ref.read(nutritionProductServiceProvider);
      await service.saveProduct(product);
      setState(() => _product = product);
      await _saveEntry();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nutritionEntrySaveError)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openSearch() async {
    final result = await Navigator.of(context).pushNamed(
      AppRouter.nutritionSearch,
      arguments: {'query': _product?.name ?? ''},
    );
    if (result is! NutritionProduct) return;
    if (!mounted) return;
    setState(() => _product = result);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final displayBarcode = _product?.barcode ?? widget.barcode;
    final isValidBarcode = _isValidBarcode(displayBarcode);
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.nutritionProductTitle),
          actions: [
            IconButton(
              tooltip: loc.nutritionProductRetryCta,
              onPressed: _loading ? null : _loadProduct,
              icon: const Icon(Icons.refresh),
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
              HeroGradientCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        SecondaryCTA(
                          label: loc.nutritionProductOpenOffCta,
                          icon: Icons.open_in_new,
                          onPressed: () => launchUrl(
                            Uri.parse(
                              'https://world.openfoodfacts.org/product/$displayBarcode',
                            ),
                          ),
                        ),
                        SecondaryCTA(
                          label: loc.nutritionSearchCta,
                          icon: Icons.search,
                          onPressed: _openSearch,
                        ),
                        SecondaryCTA(
                          label: 'Mahlzeit: ${_mealLabel(_meal)}',
                          icon: Icons.restaurant_menu,
                          onPressed: _pickMeal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!isValidBarcode) ...[
                      Text(
                        loc.nutritionBarcodeInvalidHint,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_product == null)
                NutritionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.nutritionProductNotFound,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _TextFieldBlock(
                        controller: _nameController,
                        label: loc.nutritionEntryNameLabel,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: _TextFieldBlock(
                              controller: _kcalController,
                              label: loc.nutritionEntryKcalLabel,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: _TextFieldBlock(
                              controller: _proteinController,
                              label: loc.nutritionEntryProteinLabel,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: _TextFieldBlock(
                              controller: _carbsController,
                              label: loc.nutritionEntryCarbsLabel,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: _TextFieldBlock(
                              controller: _fatController,
                              label: loc.nutritionEntryFatLabel,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _TextFieldBlock(
                        controller: _gramsController,
                        label: loc.nutritionProductGramsLabel,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PrimaryCTA(
                        label: loc.nutritionProductSaveCta,
                        icon: Icons.save_outlined,
                        onPressed: _saving ? null : _saveManualProduct,
                      ),
                    ],
                  ),
                )
              else ...[
                NutritionCard(
                  background: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _product!.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(loc.nutritionProductPer100g,
                          style: theme.textTheme.labelMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          MacroPill(
                            label: loc.nutritionEntryKcalLabel,
                            value: '${_product!.kcalPer100} kcal',
                            color: theme.colorScheme.primary,
                          ),
                          MacroPill(
                            label: loc.nutritionEntryProteinLabel,
                            value: '${_product!.proteinPer100} g',
                            color: theme.colorScheme.secondary,
                          ),
                          MacroPill(
                            label: loc.nutritionEntryCarbsLabel,
                            value: '${_product!.carbsPer100} g',
                            color: theme.colorScheme.tertiary ?? Colors.orange,
                          ),
                          MacroPill(
                            label: loc.nutritionEntryFatLabel,
                            value: '${_product!.fatPer100} g',
                            color: Colors.amber,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                NutritionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.nutritionProductGramsLabel,
                          style: theme.textTheme.labelMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _gramsController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        autocorrect: false,
                        enableSuggestions: false,
                        textCapitalization: TextCapitalization.none,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.colorScheme.surface.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.4),
                            ),
                          ),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
                NutritionCard(
                  child: _ComputedCard(
                    calories: _scaledInt(_product!.kcalPer100, _grams()),
                    protein: _scaledInt(_product!.proteinPer100, _grams()),
                    carbs: _scaledInt(_product!.carbsPer100, _grams()),
                    fat: _scaledInt(_product!.fatPer100, _grams()),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryCTA(
                  label: loc.nutritionProductAddCta,
                  icon: Icons.check_circle,
                  onPressed: _saving ? null : _saveEntry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final String value;

  const _MacroRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value),
        ],
      ),
    );
  }
}

class _ComputedCard extends StatelessWidget {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const _ComputedCard({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.nutritionProductComputedTitle),
        const SizedBox(height: 8),
        _MacroRow(label: loc.nutritionEntryKcalLabel, value: '$calories kcal'),
        _MacroRow(label: loc.nutritionEntryProteinLabel, value: '$protein g'),
        _MacroRow(label: loc.nutritionEntryCarbsLabel, value: '$carbs g'),
        _MacroRow(label: loc.nutritionEntryFatLabel, value: '$fat g'),
      ],
    );
  }
}

class _TextFieldBlock extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  const _TextFieldBlock({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: theme.colorScheme.surface.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.35),
          ),
        ),
        isDense: true,
      ),
    );
  }
}
