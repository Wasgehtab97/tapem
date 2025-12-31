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

class NutritionEntryScreen extends ConsumerStatefulWidget {
  final String? initialBarcode;
  final String? initialName;
  const NutritionEntryScreen({
    super.key,
    this.initialBarcode,
    this.initialName,
  });

  @override
  ConsumerState<NutritionEntryScreen> createState() =>
      _NutritionEntryScreenState();
}

class _NutritionEntryScreenState extends ConsumerState<NutritionEntryScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _kcalController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _qtyController;
  bool _isSaving = false;
  bool _isLookup = false;
  bool _isSearch = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _barcodeController = TextEditingController();
    _kcalController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
    _qtyController = TextEditingController();
    if (widget.initialBarcode != null && widget.initialBarcode!.isNotEmpty) {
      _barcodeController.text = widget.initialBarcode!;
    }
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _nameController.text = widget.initialName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  int _parseInt(String raw) {
    final sanitized = raw.trim();
    if (sanitized.isEmpty) return 0;
    return int.tryParse(sanitized) ?? 0;
  }

  double? _parseDouble(String raw) {
    final sanitized = raw.trim();
    if (sanitized.isEmpty) return null;
    return double.tryParse(sanitized.replaceAll(',', '.'));
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
      _nameController.text = product.name;
      _kcalController.text = product.kcalPer100.toString();
      _proteinController.text = product.proteinPer100.toString();
      _carbsController.text = product.carbsPer100.toString();
      _fatController.text = product.fatPer100.toString();
      if (_qtyController.text.trim().isEmpty) {
        _qtyController.text = '100';
      }
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
      _nameController.text = result.name;
      _kcalController.text = result.kcalPer100.toString();
      _proteinController.text = result.proteinPer100.toString();
      _carbsController.text = result.carbsPer100.toString();
      _fatController.text = result.fatPer100.toString();
      if (_barcodeController.text.trim().isEmpty) {
        _barcodeController.text = result.barcode;
      }
      if (_qtyController.text.trim().isEmpty) {
        _qtyController.text = '100';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nutritionEntryLookupFound)),
      );
    } finally {
      if (mounted) setState(() => _isSearch = false);
    }
  }

  Future<void> _saveEntry() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.userId;
    if (uid == null || uid.isEmpty) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);
    final entry = NutritionEntry(
      name: name,
      kcal: _parseInt(_kcalController.text),
      protein: _parseInt(_proteinController.text),
      carbs: _parseInt(_carbsController.text),
      fat: _parseInt(_fatController.text),
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      qty: _parseDouble(_qtyController.text),
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
      Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.nutritionEntryTitle),
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
                        child: SecondaryCTA(
                          label: loc.nutritionSearchCta,
                          icon: Icons.search,
                          onPressed: _isSearch ? null : _openSearch,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: SecondaryCTA(
                          label: loc.nutritionEntryLookupCta,
                          icon: Icons.qr_code_scanner,
                          onPressed: _isLookup ? null : _lookupBarcode,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            NutritionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldCard(
                    controller: _nameController,
                    label: loc.nutritionEntryNameLabel,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _FieldCard(
                    controller: _barcodeController,
                    label: loc.nutritionEntryBarcodeLabel,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: _FieldCard(
                          controller: _kcalController,
                          label: loc.nutritionEntryKcalLabel,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: _FieldCard(
                          controller: _proteinController,
                          label: loc.nutritionEntryProteinLabel,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: _FieldCard(
                          controller: _carbsController,
                          label: loc.nutritionEntryCarbsLabel,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: _FieldCard(
                          controller: _fatController,
                          label: loc.nutritionEntryFatLabel,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _FieldCard(
                    controller: _qtyController,
                    label: loc.nutritionEntryQtyLabel,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
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
          ],
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _FieldCard({
    required this.controller,
    required this.label,
    this.trailing,
    this.keyboardType,
    this.textInputAction,
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
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
