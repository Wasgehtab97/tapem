import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_product.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/features/nutrition/providers/nutrition_product_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

class NutritionSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  const NutritionSearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<NutritionSearchScreen> createState() =>
      _NutritionSearchScreenState();
}

class _NutritionSearchScreenState
    extends ConsumerState<NutritionSearchScreen> {
  static const _minChars = 2;
  late final TextEditingController _controller;
  bool _loading = false;
  String? _error;
  List<NutritionProduct> _results = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final query = _controller.text.trim();
      if (query.length >= _minChars) {
        _runSearch(query);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    if (q.length < _minChars) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(nutritionProductServiceProvider);
      final results = await service.searchByName(q);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildState(AppLocalizations loc) {
    final query = _controller.text.trim();
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(loc.nutritionSearchError));
    }
    if (query.length < _minChars) {
      return Center(child: Text(loc.nutritionSearchMinChars));
    }
    if (_results.isEmpty) {
      return Center(child: Text(loc.nutritionSearchEmpty));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(
        top: AppSpacing.xs,
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        bottom: AppSpacing.lg,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final product = _results[index];
        return NutritionCard(
          onTap: () => Navigator.of(context).pop(product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                '${loc.nutritionSearchMacroLine(
                  product.kcalPer100,
                  product.proteinPer100,
                  product.carbsPer100,
                  product.fatPer100,
                )} (${loc.nutritionProductPer100g})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.nutritionSearchTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: HeroGradientCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.nutritionSearchTitle,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: loc.nutritionSearchHint,
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.card),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          onPressed:
                              _loading ? null : () => _runSearch(_controller.text),
                          icon: const Icon(Icons.search),
                        ),
                      ),
                      onSubmitted: _runSearch,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _buildState(loc)),
          ],
        ),
      ),
    );
  }
}
