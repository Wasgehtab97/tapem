import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_product.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/features/nutrition/providers/nutrition_product_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

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
  bool _filteredZero = false;

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
        _filteredZero = false;
      });
      return;
    }
    
    setState(() {
      _loading = true;
      _error = null;
      _filteredZero = false;
    });
    
    try {
      final service = ref.read(nutritionProductServiceProvider);
      final results = await service.searchByName(q);
      final filtered = results
          .where((p) =>
              (p.kcalPer100 + p.proteinPer100 + p.carbsPer100 + p.fatPer100) >
              0)
          .toList();
      if (!mounted) return;
      setState(() {
        _results = filtered;
        _filteredZero = results.length != filtered.length;
      });
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandGradientIcon(Icons.error_outline_rounded, size: 64),
              const SizedBox(height: AppSpacing.md),
              Text(
                loc.nutritionSearchError,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    if (query.length < _minChars) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandGradientIcon(Icons.search_rounded, size: 64),
              const SizedBox(height: AppSpacing.md),
              Text(
                loc.nutritionSearchMinChars,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandGradientIcon(Icons.inbox_rounded, size: 64),
              const SizedBox(height: AppSpacing.md),
              Text(
                loc.nutritionSearchEmpty,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
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
        
        // Staggered fade-in animation
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 200 + (index * 50).clamp(0, 400)),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: NutritionCard(
            onTap: () => Navigator.of(context).pop(product),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    MacroPill(
                      label: '',
                      value: '${product.kcalPer100} kcal',
                      color: Theme.of(context)
                          .extension<AppBrandTheme>()
                          ?.outline ??
                          Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'P:${product.proteinPer100}g C:${product.carbsPer100}g F:${product.fatPer100}g',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.6),
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '(${loc.nutritionProductPer100g})',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.color
                            ?.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.nutritionSearchTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Premium search field with glassmorphism
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: HeroGradientCard(
                enableBackdropBlur: true,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrandGradientText(
                      loc.nutritionSearchTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      autofocus: true,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: loc.nutritionSearchHint,
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          borderSide: BorderSide(
                            color: brandColor.withOpacity(0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          borderSide: BorderSide(
                            color: brandColor.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          borderSide: BorderSide(
                            color: brandColor.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: BrandGradientIcon(Icons.search_rounded, size: 24),
                        ),
                        suffixIcon: _loading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                onPressed: _loading ? null : () => _runSearch(_controller.text),
                                icon: const BrandGradientIcon(Icons.arrow_forward_rounded),
                              ),
                      ),
                      onSubmitted: _runSearch,
                    ),
                  ],
                ),
              ),
            ),
            
            // Filtered hint
            if (_filteredZero)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  'Einige Ergebnisse ohne Nährwerte wurden ausgeblendet.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.labelSmall?.color?.withOpacity(0.6),
                  ),
                ),
              ),
            
            // Results
            Expanded(child: _buildState(loc)),
          ],
        ),
      ),
    );
  }
}
