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
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/core/widgets/brand_outline_button.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
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
      await ref
          .read(nutritionProvider)
          .addEntry(uid: uid, date: date, entry: entry);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.nutritionEntrySaved),
        ),
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.nutritionEntrySaveError),
        ),
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
      if (_isValidBarcode(product.barcode)) {
        try {
          await service.saveProduct(product);
        } catch (_) {
          // Persisting a custom product is optional for this flow.
        }
      }
      setState(() => _product = product);
      await _saveEntry();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.nutritionEntrySaveError),
        ),
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
              NutritionCard(
                padding: const EdgeInsets.all(AppSpacing.sm),
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                // Product Header (already HeroGradientCard conceptually, but ensure content looks good)
                NutritionCard(
                  neutral: true, // Darker neutral card
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BrandGradientText(
                        _product!.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        loc.nutritionProductPer100g,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          MacroPill(
                            label: loc.nutritionEntryKcalLabel,
                            value: '${_product!.kcalPer100} kcal',
                            color: AppColors.accentTurquoise,
                          ),
                          MacroPill(
                            label: loc.nutritionEntryProteinLabel,
                            value: '${_product!.proteinPer100} g',
                            color: AppColors.accentMint,
                          ),
                          MacroPill(
                            label: loc.nutritionEntryCarbsLabel,
                            value: '${_product!.carbsPer100} g',
                            color: AppColors.accentTurquoise,
                          ),
                          MacroPill(
                            label: loc.nutritionEntryFatLabel,
                            value: '${_product!.fatPer100} g',
                            color: AppColors.accentAmber,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Quantity Input
                NutritionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.nutritionProductGramsLabel,
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      BrandInteractiveCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        backgroundColor: theme.scaffoldBackgroundColor
                            .withOpacity(0.3),
                        enableScaleAnimation: false,
                        showShadow: false,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _gramsController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                autocorrect: false,
                                enableSuggestions: false,
                                textCapitalization: TextCapitalization.none,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  suffixText: 'g',
                                ),
                              ),
                            ),
                            // Quick adjust buttons
                            IconButton(
                              onPressed: () {
                                double val = _grams();
                                if (val >= 10) {
                                  _gramsController.text = (val - 10)
                                      .toInt()
                                      .toString();
                                }
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                double val = _grams();
                                _gramsController.text = (val + 10)
                                    .toInt()
                                    .toString();
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Computed Totals
                NutritionCard(
                  child: _ComputedCard(
                    calories: _scaledInt(_product!.kcalPer100, _grams()),
                    protein: _scaledInt(_product!.proteinPer100, _grams()),
                    carbs: _scaledInt(_product!.carbsPer100, _grams()),
                    fat: _scaledInt(_product!.fatPer100, _grams()),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Action Button
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
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    // Use the premium grid layout
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandGradientText(
          loc.nutritionProductComputedTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3,
          children: [
            MacroPill(
              label: loc.nutritionEntryKcalLabel,
              value: '$calories kcal',
              color: AppColors.accentTurquoise,
            ),
            MacroPill(
              label: loc.nutritionEntryProteinLabel,
              value: '$protein g',
              color: AppColors.accentMint,
            ),
            MacroPill(
              label: loc.nutritionEntryCarbsLabel,
              value: '$carbs g',
              color: AppColors.accentTurquoise,
            ),
            MacroPill(
              label: loc.nutritionEntryFatLabel,
              value: '$fat g',
              color: AppColors.accentAmber,
            ),
          ],
        ),
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
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;

    return BrandInteractiveCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.3),
      enableScaleAnimation: false,
      showShadow: false,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.none,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: brandColor.withOpacity(0.7)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
