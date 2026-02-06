import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_entry.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_product.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_totals.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/features/nutrition/data/nutrition_recents_store.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_recent_item.dart';
import 'package:tapem/features/nutrition/providers/nutrition_product_provider.dart';
import 'package:tapem/features/nutrition/providers/nutrition_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_recipe.dart';
import 'package:tapem/features/nutrition/domain/utils/nutrition_recipe_math.dart';

class NutritionEntryScreen extends ConsumerStatefulWidget {
  final String? initialBarcode;
  final String? initialName;
  final String initialMeal;
  final NutritionProduct? initialProduct;
  final double? initialQty;
  final int? entryIndex;
  final DateTime? initialDate;
  final NutritionRecipe? initialRecipe;
  const NutritionEntryScreen({
    super.key,
    this.initialBarcode,
    this.initialName,
    this.initialMeal = 'breakfast',
    this.initialProduct,
    this.initialQty,
    this.entryIndex,
    this.initialDate,
    this.initialRecipe,
  });

  @override
  ConsumerState<NutritionEntryScreen> createState() =>
      _NutritionEntryScreenState();
}

class _NutritionEntryScreenState extends ConsumerState<NutritionEntryScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  NutritionProduct? _product;
  late final TextEditingController _qtyController;
  late final FocusNode _qtyFocus;
  late final FocusNode _nameFocus;
  // Manuelle Nährwerte (pro 100 g)
  late final TextEditingController _kcalPer100Ctrl;
  late final TextEditingController _proteinPer100Ctrl;
  late final TextEditingController _carbsPer100Ctrl;
  late final TextEditingController _fatPer100Ctrl;
  late final FocusNode _kcalFocus;
  late final FocusNode _proteinFocus;
  late final FocusNode _carbsFocus;
  late final FocusNode _fatFocus;
  late final List<TextEditingController> _macroCtrls;
  late final List<FocusNode> _macroFocus;
  int _macroIndex = 0;
  bool _isSaving = false;
  bool _isLookup = false;
  bool _isSearch = false;
  String _meal = 'breakfast';
  bool _showManualMacros = false;
  List<RecipeIngredient>? _ingredients;

  bool get _isEditing => widget.entryIndex != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _barcodeController = TextEditingController();
    _qtyController = TextEditingController(text: '100');
    _qtyFocus = FocusNode();
    _nameFocus = FocusNode();
    _kcalPer100Ctrl = TextEditingController();
    _proteinPer100Ctrl = TextEditingController();
    _carbsPer100Ctrl = TextEditingController();
    _fatPer100Ctrl = TextEditingController();
    _kcalFocus = FocusNode();
    _proteinFocus = FocusNode();
    _carbsFocus = FocusNode();
    _fatFocus = FocusNode();
    _macroCtrls = [
      _kcalPer100Ctrl,
      _proteinPer100Ctrl,
      _carbsPer100Ctrl,
      _fatPer100Ctrl,
    ];
    _macroFocus = [_kcalFocus, _proteinFocus, _carbsFocus, _fatFocus];
    // Makro-Felder starten leer; werden bei Lookup/Scan befüllt.
    _nameFocus.addListener(_onNameFocusChange);
    _meal = widget.initialMeal;
    if (widget.initialBarcode != null && widget.initialBarcode!.isNotEmpty) {
      _barcodeController.text = widget.initialBarcode!;
    }
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _nameController.text = widget.initialName!;
    }
    if (widget.initialProduct != null) {
      _product = widget.initialProduct;
      _syncMacroCtrlsFromProduct(_product!);
    }
    if (widget.initialQty != null && widget.initialQty! > 0) {
      _qtyController.text = widget.initialQty!.toString();
    }
    if (widget.initialRecipe != null) {
      _ingredients = List.from(widget.initialRecipe!.ingredients);
      _updateMacrosFromIngredients();
    }
    if (_barcodeController.text.isNotEmpty && widget.initialRecipe == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lookupBarcode();
      });
    }
  }

  void _updateMacrosFromIngredients() {
    if (_ingredients == null || _ingredients!.isEmpty) return;
    final summary = summarizeRecipeIngredients(_ingredients!);
    if (summary.grams <= 0) return;
    _kcalPer100Ctrl.text = summary.kcalPer100.toString();
    _proteinPer100Ctrl.text = summary.proteinPer100.toString();
    _carbsPer100Ctrl.text = summary.carbsPer100.toString();
    _fatPer100Ctrl.text = summary.fatPer100.toString();
    _qtyController.text = _formatGrams(summary.grams);
  }

  @override
  void dispose() {
    // Remove listeners before disposing to avoid them triggering during disposal
    _nameFocus.removeListener(_onNameFocusChange);

    _nameController.dispose();
    _barcodeController.dispose();
    _qtyController.dispose();
    _qtyFocus.dispose();
    _nameFocus.dispose();
    _kcalFocus.dispose();
    _proteinFocus.dispose();
    _carbsFocus.dispose();
    _fatFocus.dispose();
    _kcalPer100Ctrl.dispose();
    _proteinPer100Ctrl.dispose();
    _carbsPer100Ctrl.dispose();
    _fatPer100Ctrl.dispose();
    super.dispose();
  }

  void _onNameFocusChange() {
    if (_nameFocus.hasFocus) {
      _closeKeypad();
    }
  }

  double? _parseDouble(String raw) {
    final sanitized = raw.trim();
    if (sanitized.isEmpty) return null;
    return double.tryParse(sanitized.replaceAll(',', '.'));
  }

  double _grams() {
    final val = _parseDouble(_qtyController.text) ?? 0;
    return val <= 0 ? 100 : val;
  }

  String get _gramsLabel => '${_grams().round()}g';

  int _per100From(TextEditingController ctrl, int fallback) {
    final v = _parseDouble(ctrl.text);
    return v == null ? fallback : v.round();
  }

  int get _kcalPer100 =>
      _per100From(_kcalPer100Ctrl, _product?.kcalPer100 ?? 0);
  int get _proteinPer100 =>
      _per100From(_proteinPer100Ctrl, _product?.proteinPer100 ?? 0);
  int get _carbsPer100 =>
      _per100From(_carbsPer100Ctrl, _product?.carbsPer100 ?? 0);
  int get _fatPer100 => _per100From(_fatPer100Ctrl, _product?.fatPer100 ?? 0);

  void _syncMacroCtrlsFromProduct(NutritionProduct product) {
    _kcalPer100Ctrl.text = product.kcalPer100.toString();
    _proteinPer100Ctrl.text = product.proteinPer100.toString();
    _carbsPer100Ctrl.text = product.carbsPer100.toString();
    _fatPer100Ctrl.text = product.fatPer100.toString();
  }

  NutritionProduct _buildProductForSave() {
    final barcode = _barcodeController.text.trim();
    return NutritionProduct(
      barcode: barcode,
      name: _nameController.text.trim(),
      kcalPer100: _kcalPer100,
      proteinPer100: _proteinPer100,
      carbsPer100: _carbsPer100,
      fatPer100: _fatPer100,
      updatedAt: DateTime.now(),
    );
  }

  bool _isPersistableGlobalBarcode(String barcode) {
    final code = barcode.trim();
    if (code.isEmpty) return false;
    if (!RegExp(r'^\d+$').hasMatch(code)) return false;
    return code.length == 8 ||
        code.length == 12 ||
        code.length == 13 ||
        code.length == 14;
  }

  void _openQtyKeypad() {
    _openNumericKeypad(
      _qtyController,
      _qtyFocus,
      allowDecimal: false,
      plusMinusRail: true,
    );
  }

  void _bumpQty(int delta) {
    final current = (_parseDouble(_qtyController.text) ?? 0).round();
    final next = (current + delta).clamp(0, 1000);
    _qtyController.text = next.toString();
    setState(() {});
  }

  void _openNumericKeypad(
    TextEditingController controller,
    FocusNode focus, {
    bool allowDecimal = false,
    bool plusMinusRail = false,
    bool railPlusMinusAndArrows = false,
    bool arrowsOnly = false,
    VoidCallback? onRailMinus,
    VoidCallback? onRailPlus,
    VoidCallback? onPrev,
    VoidCallback? onNext,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    final keypad = ref.read(overlayNumericKeypadControllerProvider);
    keypad.openFor(
      controller,
      allowDecimal: allowDecimal,
      integerStep: 1,
      decimalStep: 1,
      railPlusMinusMode: plusMinusRail,
      railPlusMinusAndArrows: railPlusMinusAndArrows,
      railArrowsOnly: arrowsOnly,
      onRailMinus: onRailMinus ?? (plusMinusRail ? () => _bumpQty(-1) : null),
      onRailPlus: onRailPlus ?? (plusMinusRail ? () => _bumpQty(1) : null),
      onConfirm: _saveEntry,
      onRailPrev: onPrev,
      onRailNext: onNext,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        focus.context ?? context,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
      if (focus.canRequestFocus) {
        focus.requestFocus();
      }
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    });
  }

  void _openMacroKeypadAt(int index) {
    _macroIndex = index.clamp(0, _macroCtrls.length - 1);
    final ctrl = _macroCtrls[index];
    final focus = _macroFocus[index];
    final prev = index > 0 ? () => _openMacroKeypadAt(index - 1) : null;
    final next = index < _macroCtrls.length - 1
        ? () => _openMacroKeypadAt(index + 1)
        : null;
    _openNumericKeypad(
      ctrl,
      focus,
      allowDecimal: false,
      plusMinusRail: true,
      arrowsOnly: false,
      railPlusMinusAndArrows: true,
      onPrev: prev,
      onNext: next,
      onRailMinus: () => _bumpMacroCurrent(-1),
      onRailPlus: () => _bumpMacroCurrent(1),
    );
  }

  void _bumpMacroCurrent(int delta) {
    final controller = _macroCtrls[_macroIndex];
    final current = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
    final next = (current + delta).clamp(0, 100000).toInt();
    setState(() => controller.text = next.toString());
  }

  void _closeKeypad() {
    if (!mounted) return;
    ref.read(overlayNumericKeypadControllerProvider).close();
  }

  NutritionEntry _buildEntry(String uid) {
    final grams = _grams();
    final name = _nameController.text.trim();
    int scale(int per100) => ((per100 * grams) / 100).round();
    final kcal = scale(_kcalPer100);
    final protein = scale(_proteinPer100);
    final carbs = scale(_carbsPer100);
    final fat = scale(_fatPer100);
    return NutritionEntry(
      name: name,
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      meal: _meal,
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      qty: grams,
    );
  }

  NutritionTotals _draftTotals() {
    final grams = _grams();
    int scale(int per100) => ((per100 * grams) / 100).round();
    return NutritionTotals(
      kcal: scale(_kcalPer100),
      protein: scale(_proteinPer100),
      carbs: scale(_carbsPer100),
      fat: scale(_fatPer100),
    );
  }

  NutritionTotals _mealTotals(String meal) {
    final log = ref.read(nutritionProvider).log;
    if (log == null) {
      return const NutritionTotals(kcal: 0, protein: 0, carbs: 0, fat: 0);
    }
    final totals = log.entries
        .where((e) => e.meal == meal)
        .fold<NutritionTotals>(
          const NutritionTotals(kcal: 0, protein: 0, carbs: 0, fat: 0),
          (acc, e) => NutritionTotals(
            kcal: acc.kcal + e.kcal,
            protein: acc.protein + e.protein,
            carbs: acc.carbs + e.carbs,
            fat: acc.fat + e.fat,
          ),
        );
    return totals;
  }

  NutritionTotals _addTotals(NutritionTotals a, NutritionTotals b) {
    return NutritionTotals(
      kcal: a.kcal + b.kcal,
      protein: a.protein + b.protein,
      carbs: a.carbs + b.carbs,
      fat: a.fat + b.fat,
    );
  }

  Future<void> _lookupBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;
    setState(() => _isLookup = true);
    try {
      final service = ref.read(nutritionProductServiceProvider);
      final product = await service.getByBarcode(barcode);
      if (product == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.nutritionEntryLookupEmpty,
            ),
          ),
        );
        return;
      }
      setState(() {
        _product = product;
        _nameController.text = product.name;
        _syncMacroCtrlsFromProduct(product);
        if (_barcodeController.text.trim().isEmpty) {
          _barcodeController.text = product.barcode;
        }
        if (_qtyController.text.trim().isEmpty) {
          _qtyController.text = '100';
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.nutritionEntryLookupFound,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.nutritionEntryLookupError,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLookup = false);
      }
    }
  }

  Future<void> _openSearch() async {
    setState(() => _isSearch = true);
    try {
      final result = await Navigator.of(context).pushNamed(
        AppRouter.nutritionSearch,
        arguments: {'query': _nameController.text.trim()},
      );
      if (result is! NutritionProduct) return;
      setState(() {
        _product = result;
        _nameController.text = result.name;
        _syncMacroCtrlsFromProduct(result);
        if (_barcodeController.text.trim().isEmpty) {
          _barcodeController.text = result.barcode;
        }
        if (_qtyController.text.trim().isEmpty) {
          _qtyController.text = '100';
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.nutritionEntryLookupFound,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSearch = false);
    }
  }

  Future<void> _openScanner() async {
    final result = await Navigator.of(context).pushNamed(
      AppRouter.nutritionScan,
      arguments: {'returnBarcode': true, 'meal': _meal},
    );
    if (result is! String || result.isEmpty) return;
    setState(() {
      _barcodeController.text = result;
    });
    await _lookupBarcode();
  }

  Future<void> _saveEntry() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.userId;
    if (uid == null || uid.isEmpty) return;
    final manualName = _nameController.text.trim();
    if (manualName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Namen eingeben.')),
      );
      return;
    }
    if (_kcalPer100 <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kalorien /100g müssen > 0 sein.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final entry = _buildEntry(uid);
    try {
      final date =
          widget.initialDate ?? ref.read(nutritionProvider).selectedDate;
      final productForSave = _buildProductForSave();
      if (_isEditing && widget.entryIndex != null) {
        await ref
            .read(nutritionProvider)
            .updateEntry(
              uid: uid,
              date: date,
              index: widget.entryIndex!,
              entry: entry,
            );
      } else {
        await ref
            .read(nutritionProvider)
            .addEntry(uid: uid, date: date, entry: entry);
      }
      final productService = ref.read(nutritionProductServiceProvider);
      if (_isPersistableGlobalBarcode(productForSave.barcode)) {
        try {
          await productService.saveProduct(productForSave);
        } catch (_) {
          // Wenn das Persistieren fehlschlägt (z.B. wegen Offline/Rules), trotzdem den Eintrag anlegen.
        }
      }
      await ref
          .read(nutritionRecentsStoreProvider)
          .add(product: productForSave, grams: _grams());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.nutritionEntrySaved),
        ),
      );
      if (_isEditing ||
          widget.initialProduct != null ||
          widget.initialBarcode != null) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _product = null;
          _nameController.clear();
          _barcodeController.clear();
          _qtyController.text = '100';
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.nutritionEntrySaveError),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatGrams(double grams) {
    if (grams % 1 == 0) return grams.toInt().toString();
    return grams.toStringAsFixed(1);
  }

  Future<void> _openRecents() async {
    final loc = AppLocalizations.of(context)!;
    final items = ref.read(nutritionRecentsStoreProvider).load();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Keine zuletzt verwendeten Produkte.')),
      );
      return;
    }
    final picked = await showModalBottomSheet<NutritionRecentItem>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final controller = TextEditingController();
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final q = controller.text.trim().toLowerCase();
              final filtered = q.isEmpty
                  ? items
                  : items
                        .where((i) => i.name.toLowerCase().contains(q))
                        .toList(growable: false);
              return SizedBox(
                height: MediaQuery.sizeOf(ctx).height * 0.75,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.xs,
                        AppSpacing.sm,
                        AppSpacing.xs,
                      ),
                      child: TextField(
                        controller: controller,
                        autocorrect: false,
                        enableSuggestions: false,
                        textCapitalization: TextCapitalization.none,
                        decoration: InputDecoration(
                          hintText: 'Zuletzt suchen…',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: controller.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setModalState(() {
                                    controller.clear();
                                  }),
                                ),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'Keine Treffer.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final item = filtered[index];
                                int scale(int per100) =>
                                    ((per100 * item.lastGrams) / 100).round();
                                final line = loc.nutritionSearchMacroLine(
                                  scale(item.kcalPer100),
                                  scale(item.proteinPer100),
                                  scale(item.carbsPer100),
                                  scale(item.fatPer100),
                                );
                                return ListTile(
                                  title: Text(item.name),
                                  subtitle: Text(
                                    '${_formatGrams(item.lastGrams)} g · $line',
                                  ),
                                  trailing: const Icon(Icons.add),
                                  onTap: () => Navigator.of(ctx).pop(item),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _product = picked.toProduct();
      _syncMacroCtrlsFromProduct(_product!);
      _nameController.text = picked.name;
      _barcodeController.text = picked.barcode ?? '';
      _qtyController.text = _formatGrams(picked.lastGrams);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final state = ref.watch(nutritionProvider);
    final goalKcal = state.goal?.kcal ?? 0;
    final dayTotals = state.log?.total;
    final mealTotals = _mealTotals(_meal);
    final draftTotals = _draftTotals();
    final combinedMeal = _addTotals(mealTotals, draftTotals);
    final remainingKcal = goalKcal - (dayTotals?.kcal ?? 0) - draftTotals.kcal;
    String mealLabel(String meal) {
      final isDe = Localizations.localeOf(
        context,
      ).languageCode.startsWith('de');
      switch (meal) {
        case 'breakfast':
          return isDe ? 'Frühstück' : 'Breakfast';
        case 'lunch':
          return isDe ? 'Mittagessen' : 'Lunch';
        case 'dinner':
          return isDe ? 'Abendessen' : 'Dinner';
        case 'snack':
          return isDe ? 'Snack' : 'Snack';
        default:
          return meal;
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(loc.nutritionEntryTitle)),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${mealLabel(_meal)} · Freie kcal: $remainingKcal',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        NutritionMealPicker(
                          selectedMeal: _meal,
                          onChanged: (m) => setState(() => _meal = m),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            MacroPill(
                              label: 'Kcal',
                              value: '${combinedMeal.kcal}',
                              color: AppColors.accentTurquoise,
                            ),
                            MacroPill(
                              label: 'P',
                              value: '${combinedMeal.protein} g',
                              color: const Color(0xFFE53935),
                            ),
                            MacroPill(
                              label: 'C',
                              value: '${combinedMeal.carbs} g',
                              color: AppColors.accentMint,
                            ),
                            MacroPill(
                              label: 'F',
                              value: '${combinedMeal.fat} g',
                              color: AppColors.accentAmber,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Circle buttons for actions - NO title needed!
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _CircleIconButton(
                                    tooltip: loc.nutritionSearchCta,
                                    icon: Icons.search,
                                    onTap: _isSearch ? null : _openSearch,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  _CircleIconButton(
                                    tooltip: loc.nutritionEntryLookupCta,
                                    icon: Icons.qr_code_scanner,
                                    onTap: _isLookup ? null : _openScanner,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  _CircleIconButton(
                                    tooltip:
                                        Localizations.localeOf(
                                          context,
                                        ).languageCode.startsWith('de')
                                        ? 'Zuletzt'
                                        : 'Recent',
                                    icon: Icons.history,
                                    onTap: _isSaving ? null : _openRecents,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  _CircleIconButton(
                                    tooltip: 'Manuell',
                                    icon: Icons.edit_note_rounded,
                                    onTap: () => setState(
                                      () => _showManualMacros =
                                          !_showManualMacros,
                                    ),
                                    active: _showManualMacros,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _FieldCard(
                                controller: _nameController,
                                label: loc.nutritionEntryNameLabel,
                                textInputAction: TextInputAction.next,
                                focusNode: _nameFocus,
                                onTap: _closeKeypad,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 180),
                                crossFadeState: _showManualMacros
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                firstChild: const SizedBox.shrink(),
                                secondChild: Column(
                                  children: [
                                    const SizedBox(height: AppSpacing.xs),
                                    _MacroFields(
                                      kcalCtrl: _kcalPer100Ctrl,
                                      proteinCtrl: _proteinPer100Ctrl,
                                      carbsCtrl: _carbsPer100Ctrl,
                                      fatCtrl: _fatPer100Ctrl,
                                      kcalFocus: _kcalFocus,
                                      proteinFocus: _proteinFocus,
                                      carbsFocus: _carbsFocus,
                                      fatFocus: _fatFocus,
                                      gramsLabel: _gramsLabel,
                                      onChanged: () => setState(() {}),
                                      onRequestKeypad: () =>
                                          _openMacroKeypadAt(0),
                                      onRequestKeypadProtein: () =>
                                          _openMacroKeypadAt(1),
                                      onRequestKeypadCarbs: () =>
                                          _openMacroKeypadAt(2),
                                      onRequestKeypadFat: () =>
                                          _openMacroKeypadAt(3),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                  ],
                                ),
                              ),
                              _QtyField(
                                controller: _qtyController,
                                focusNode: _qtyFocus,
                                onRequestKeypad: _openQtyKeypad,
                                onChanged: () => setState(() {}),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _ComputedPanel(
                                grams: _grams(),
                                product: _buildProductForSave(),
                                theme: Theme.of(context),
                                loc: loc,
                              ),
                              if (_ingredients != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                _RecipeIngredientsList(
                                  ingredients: _ingredients!,
                                  onIngredientsChanged: (updated) {
                                    setState(() {
                                      _ingredients = updated;
                                      _updateMacrosFromIngredients();
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        PrimaryCTA(
                          label: loc.nutritionEntrySaveCta,
                          icon: Icons.check_circle,
                          onPressed: _isSaving ? null : _saveEntry,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Premium input field with brand interactive styling - NO ugly borders!

class _FieldCard extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool showCursor;
  final bool enableInteractiveSelection;

  const _FieldCard({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.focusNode,
    this.readOnly = false,
    this.onTap,
    this.showCursor = true,
    this.enableInteractiveSelection = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;
    final fieldRadius = BorderRadius.circular(16);

    return Container(
      decoration: BoxDecoration(
        borderRadius: fieldRadius,
        color: theme.colorScheme.surface.withOpacity(0.14),
      ),
      child: ClipRRect(
        borderRadius: fieldRadius,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              brandColor.withOpacity(0.95),
                              brandColor.withOpacity(0.45),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: brandColor.withOpacity(0.88),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: keyboardType,
                    textInputAction: textInputAction,
                    onChanged: onChanged,
                    readOnly: readOnly,
                    onTap: onTap,
                    showCursor: showCursor,
                    enableInteractiveSelection: enableInteractiveSelection,
                    scrollPadding: const EdgeInsets.only(bottom: 200),
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.none,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                      height: 1.15,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium panel with NO borders - glassmorphism effect
class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withOpacity(0.3),
        borderRadius:
            brand?.outlineRadius as BorderRadius? ??
            BorderRadius.circular(AppRadius.cardLg),
      ),
      child: child,
    );
  }
}

class _QtyField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final FocusNode focusNode;
  final VoidCallback onRequestKeypad;

  const _QtyField({
    required this.controller,
    required this.onChanged,
    required this.focusNode,
    required this.onRequestKeypad,
  });

  double _value() => double.tryParse(controller.text) ?? 0;

  void _bump(int delta) {
    final current = _value().round();
    final next = (current + delta).clamp(0, 1000);
    controller.text = next.toString();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldCard(
          controller: controller,
          label: 'Menge (g)',
          keyboardType: TextInputType.none,
          textInputAction: TextInputAction.done,
          onChanged: (_) => onChanged(),
          focusNode: focusNode,
          readOnly: true,
          showCursor: true,
          enableInteractiveSelection: false,
          onTap: onRequestKeypad,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _QtyIconButton(icon: Icons.remove, onTap: () => _bump(-1)),
            Expanded(
              child: Slider(
                value: _value().clamp(0, 1000),
                min: 0,
                max: 1000,
                divisions: 200, // 5g Schritte
                label: '${controller.text} g',
                activeColor: theme.colorScheme.primary,
                onChanged: (v) {
                  final snapped = (v / 5).round() * 5;
                  controller.text = snapped.toInt().toString();
                  onChanged();
                },
              ),
            ),
            _QtyIconButton(icon: Icons.add, onTap: () => _bump(1)),
          ],
        ),
      ],
    );
  }
}

class _QtyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.35),
          ),
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.onSurface),
      ),
    );
  }
}

class _MacroFields extends StatelessWidget {
  final TextEditingController kcalCtrl;
  final TextEditingController proteinCtrl;
  final TextEditingController carbsCtrl;
  final TextEditingController fatCtrl;
  final VoidCallback onChanged;
  final VoidCallback onRequestKeypad;
  final VoidCallback onRequestKeypadProtein;
  final VoidCallback onRequestKeypadCarbs;
  final VoidCallback onRequestKeypadFat;
  final FocusNode kcalFocus;
  final FocusNode proteinFocus;
  final FocusNode carbsFocus;
  final FocusNode fatFocus;
  final String gramsLabel;

  const _MacroFields({
    required this.kcalCtrl,
    required this.proteinCtrl,
    required this.carbsCtrl,
    required this.fatCtrl,
    required this.onChanged,
    required this.onRequestKeypad,
    required this.onRequestKeypadProtein,
    required this.onRequestKeypadCarbs,
    required this.onRequestKeypadFat,
    required this.kcalFocus,
    required this.proteinFocus,
    required this.carbsFocus,
    required this.fatFocus,
    required this.gramsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _FieldCard(
                controller: kcalCtrl,
                label: 'Kalorien /100g',
                focusNode: kcalFocus,
                keyboardType: TextInputType.none,
                readOnly: true,
                showCursor: true,
                enableInteractiveSelection: false,
                onTap: onRequestKeypad,
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _FieldCard(
                controller: proteinCtrl,
                label: 'Protein /100g',
                focusNode: proteinFocus,
                keyboardType: TextInputType.none,
                readOnly: true,
                showCursor: true,
                enableInteractiveSelection: false,
                onTap: onRequestKeypadProtein,
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _FieldCard(
                controller: carbsCtrl,
                label: 'Carbs /100g',
                focusNode: carbsFocus,
                keyboardType: TextInputType.none,
                readOnly: true,
                showCursor: true,
                enableInteractiveSelection: false,
                onTap: onRequestKeypadCarbs,
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _FieldCard(
                controller: fatCtrl,
                label: 'Fett /100g',
                focusNode: fatFocus,
                keyboardType: TextInputType.none,
                readOnly: true,
                showCursor: true,
                enableInteractiveSelection: false,
                onTap: onRequestKeypadFat,
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  const _CircleIconButton({
    required this.tooltip,
    required this.icon,
    this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final outline = brand?.outline ?? theme.colorScheme.primary;
    final bg = theme.colorScheme.surface.withOpacity(0.22);
    final gradient = LinearGradient(
      colors: [
        outline.withOpacity(active ? 0.24 : 0.14),
        outline.withOpacity(0.03),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: gradient,
            border: Border.all(color: outline.withOpacity(0.28), width: 1),
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: active ? outline : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _ComputedPanel extends StatelessWidget {
  final double grams;
  final NutritionProduct? product;
  final ThemeData theme;
  final AppLocalizations loc;

  const _ComputedPanel({
    required this.grams,
    required this.product,
    required this.theme,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    int scale(int per100) => ((per100 * grams) / 100).round();
    final kcal = scale(product?.kcalPer100 ?? 0);
    final protein = scale(product?.proteinPer100 ?? 0);
    final carbs = scale(product?.carbsPer100 ?? 0);
    final fat = scale(product?.fatPer100 ?? 0);
    final panelColor = theme.colorScheme.surfaceVariant.withOpacity(0.15);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.nutritionProductComputedTitle,
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
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
                value: '$kcal kcal',
                color: Colors.blueAccent,
              ),
              MacroPill(
                label: loc.nutritionEntryProteinLabel,
                value: '$protein g',
                color: Colors.redAccent,
              ),
              MacroPill(
                label: loc.nutritionEntryCarbsLabel,
                value: '$carbs g',
                color: Colors.greenAccent.shade400,
              ),
              MacroPill(
                label: loc.nutritionEntryFatLabel,
                value: '$fat g',
                color: Colors.amber.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecipeIngredientsList extends StatefulWidget {
  final List<RecipeIngredient> ingredients;
  final ValueChanged<List<RecipeIngredient>> onIngredientsChanged;

  const _RecipeIngredientsList({
    required this.ingredients,
    required this.onIngredientsChanged,
  });

  @override
  State<_RecipeIngredientsList> createState() => _RecipeIngredientsListState();
}

class _RecipeIngredientsListState extends State<_RecipeIngredientsList> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.ingredients
        .map<TextEditingController>(
          (ing) => TextEditingController(text: ing.grams.toStringAsFixed(0)),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final ctrl in _controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.list_alt_rounded, size: 18),
            const SizedBox(width: 8),
            Text(
              'Zutaten anpassen',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...widget.ingredients.asMap().entries.map((entry) {
          final idx = entry.key;
          final ing = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: brandColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ing.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${ing.kcalPer100} kcal/100g',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _controllers[idx],
                    decoration: const InputDecoration(
                      suffixText: 'g',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: theme.textTheme.bodyMedium,
                    onChanged: (v) {
                      final val = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                      final updated = List<RecipeIngredient>.from(
                        widget.ingredients,
                      );
                      updated[idx] = RecipeIngredient(
                        name: ing.name,
                        barcode: ing.barcode,
                        kcalPer100: ing.kcalPer100,
                        proteinPer100: ing.proteinPer100,
                        carbsPer100: ing.carbsPer100,
                        fatPer100: ing.fatPer100,
                        grams: val,
                      );
                      widget.onIngredientsChanged(updated);
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
