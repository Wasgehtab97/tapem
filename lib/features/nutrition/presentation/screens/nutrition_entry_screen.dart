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

class NutritionEntryScreen extends ConsumerStatefulWidget {
  final String? initialBarcode;
  final String? initialName;
  final String initialMeal;
  final NutritionProduct? initialProduct;
  final double? initialQty;
  final int? entryIndex;
  const NutritionEntryScreen({
    super.key,
    this.initialBarcode,
    this.initialName,
    this.initialMeal = 'breakfast',
    this.initialProduct,
    this.initialQty,
    this.entryIndex,
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
  bool _isSaving = false;
  bool _isLookup = false;
  bool _isSearch = false;
  String _meal = 'breakfast';

  bool get _isEditing => widget.entryIndex != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _barcodeController = TextEditingController();
    _qtyController = TextEditingController(text: '100');
    _meal = widget.initialMeal;
    if (widget.initialBarcode != null && widget.initialBarcode!.isNotEmpty) {
      _barcodeController.text = widget.initialBarcode!;
    }
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _nameController.text = widget.initialName!;
    }
    if (widget.initialProduct != null) {
      _product = widget.initialProduct;
    }
    if (widget.initialQty != null && widget.initialQty! > 0) {
      _qtyController.text = widget.initialQty!.toString();
    }
    if (_barcodeController.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lookupBarcode();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _qtyController.dispose();
    super.dispose();
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

  NutritionEntry _buildEntry(String uid) {
    final grams = _grams();
    final name = _nameController.text.trim();
    int scale(int per100) => ((per100 * grams) / 100).round();
    final kcal = scale(_product?.kcalPer100 ?? 0);
    final protein = scale(_product?.proteinPer100 ?? 0);
    final carbs = scale(_product?.carbsPer100 ?? 0);
    final fat = scale(_product?.fatPer100 ?? 0);
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
      kcal: scale(_product?.kcalPer100 ?? 0),
      protein: scale(_product?.proteinPer100 ?? 0),
      carbs: scale(_product?.carbsPer100 ?? 0),
      fat: scale(_product?.fatPer100 ?? 0),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.nutritionEntryLookupEmpty)),
        );
        return;
      }
      setState(() {
        _product = product;
        _nameController.text = product.name;
        if (_barcodeController.text.trim().isEmpty) {
          _barcodeController.text = product.barcode;
        }
        if (_qtyController.text.trim().isEmpty) {
          _qtyController.text = '100';
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nutritionEntryLookupFound)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nutritionEntryLookupError)),
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
        if (_barcodeController.text.trim().isEmpty) {
          _barcodeController.text = result.barcode;
        }
        if (_qtyController.text.trim().isEmpty) {
          _qtyController.text = '100';
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nutritionEntryLookupFound)),
      );
    } finally {
      if (mounted) setState(() => _isSearch = false);
    }
  }

  Future<void> _openScanner() async {
    final result = await Navigator.of(context).pushNamed(
      AppRouter.nutritionScan,
      arguments: {
        'returnBarcode': true,
        'meal': _meal,
      },
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
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);
    final entry = _buildEntry(uid);
    try {
      final date = ref.read(nutritionProvider).selectedDate;
      if (_isEditing && widget.entryIndex != null) {
        await ref.read(nutritionProvider).updateEntry(
              uid: uid,
              date: date,
              index: widget.entryIndex!,
              entry: entry,
            );
      } else {
        await ref.read(nutritionProvider).addEntry(
              uid: uid,
              date: date,
              entry: entry,
            );
      }
      final product = _product;
      if (product != null) {
        await ref.read(nutritionRecentsStoreProvider).add(
              product: product,
              grams: _grams(),
            );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nutritionEntrySaved)),
      );
      if (_isEditing) {
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
        SnackBar(content: Text(AppLocalizations.of(context)!.nutritionEntrySaveError)),
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
    final remainingKcal =
        goalKcal - (dayTotals?.kcal ?? 0) - draftTotals.kcal;
    String mealLabel(String meal) {
      final isDe = Localizations.localeOf(context).languageCode.startsWith('de');
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
    final isDe = Localizations.localeOf(context).languageCode.startsWith('de');
    final mealTitle = isDe ? 'Mahlzeit' : 'Meal';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.nutritionEntryTitle),
        ),
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
                        Text(
                          '$mealTitle: ${mealLabel(_meal)} · Freie kcal: $remainingKcal',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            MacroPill(
                              label: 'Kcal',
                              value: '${combinedMeal.kcal}',
                              color: Colors.blueAccent,
                            ),
                            MacroPill(
                              label: 'P',
                              value: '${combinedMeal.protein} g',
                              color: Colors.redAccent,
                            ),
                            MacroPill(
                              label: 'C',
                              value: '${combinedMeal.carbs} g',
                              color: Colors.greenAccent.shade400,
                            ),
                            MacroPill(
                              label: 'F',
                              value: '${combinedMeal.fat} g',
                              color: Colors.amber.shade700,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.nutritionEntryTitle,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionButtonEntry(
                                      label: loc.nutritionSearchCta,
                                      icon: Icons.search,
                                      onPressed: _isSearch ? null : _openSearch,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: _ActionButtonEntry(
                                      label: loc.nutritionEntryLookupCta,
                                      icon: Icons.qr_code_scanner,
                                      onPressed: _isLookup ? null : _openScanner,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: _ActionButtonEntry(
                                      label: Localizations.localeOf(context)
                                              .languageCode
                                              .startsWith('de')
                                          ? 'Zuletzt'
                                          : 'Recent',
                                      icon: Icons.history,
                                      onPressed: _isSaving ? null : _openRecents,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _FieldCard(
                                controller: _nameController,
                                label: loc.nutritionEntryNameLabel,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _QtyField(
                                controller: _qtyController,
                                onChanged: () => setState(() {}),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _ComputedPanel(
                                grams: _grams(),
                                product: _product,
                                theme: Theme.of(context),
                                loc: loc,
                              ),
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

class _FieldCard extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  const _FieldCard({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onChanged: onChanged,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: child,
    );
  }
}

class _QtyField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _QtyField({
    required this.controller,
    required this.onChanged,
  });

  double _value() => double.tryParse(controller.text) ?? 100;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldCard(
          controller: controller,
          label: 'Menge (g)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          onChanged: (_) => onChanged(),
        ),
        Slider(
          value: _value().clamp(10, 2000),
          min: 10,
          max: 2000,
          divisions: 199,
          label: '${controller.text} g',
          activeColor: theme.colorScheme.primary,
          onChanged: (v) {
            controller.text = v.round().toString();
            onChanged();
          },
        ),
      ],
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
    final border = theme.colorScheme.outline.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: border),
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

class _ActionButtonEntry extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ActionButtonEntry({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final outline = brand?.outline ?? theme.colorScheme.primary;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: ElevatedButton.styleFrom(
        backgroundColor: outline.withOpacity(0.15),
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          side: BorderSide(color: outline.withOpacity(0.35)),
        ),
      ),
    );
  }
}
