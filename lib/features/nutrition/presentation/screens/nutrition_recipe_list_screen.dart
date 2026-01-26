import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/features/nutrition/providers/nutrition_provider.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_recipe.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

class NutritionRecipeListScreen extends ConsumerStatefulWidget {
  const NutritionRecipeListScreen({super.key});

  @override
  ConsumerState<NutritionRecipeListScreen> createState() =>
      _NutritionRecipeListScreenState();
}

class _NutritionRecipeListScreenState
    extends ConsumerState<NutritionRecipeListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecipes());
  }

  Future<void> _loadRecipes() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.userId;
    if (uid == null || uid.isEmpty) return;
    await ref.read(nutritionProvider).loadRecipes(uid);
  }

  int _computeTotals(NutritionRecipe recipe, String field) {
    int scale(int per100, double grams) => ((per100 * grams) / 100).round();
    int total = 0;
    for (final ing in recipe.ingredients) {
      switch (field) {
        case 'kcal':
          total += scale(ing.kcalPer100, ing.grams);
          break;
        case 'protein':
          total += scale(ing.proteinPer100, ing.grams);
          break;
        case 'carbs':
          total += scale(ing.carbsPer100, ing.grams);
          break;
        case 'fat':
          total += scale(ing.fatPer100, ing.grams);
          break;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final state = ref.watch(nutritionProvider);
    final recipes = state.recipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerichte'),
      ),
      body: recipes.isEmpty
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Erstelle eigene Rezepte und füge sie schnell zu deinen Mahlzeiten hinzu.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRouter.nutritionRecipeEdit),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.sm),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                
                // Staggered animation
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 150 + (index * 50).clamp(0, 300)),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 15 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: NutritionCard(
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRouter.nutritionRecipeEdit,
                      arguments: recipe.id,
                    ),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: BrandGradientText(
                                recipe.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Theme.of(context)
                                        .extension<AppBrandTheme>()
                                        ?.outline
                                        .withOpacity(0.15) ??
                                        Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withOpacity(0.15),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: const BrandGradientIcon(
                                Icons.chevron_right_rounded,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: MacroPill(
                                label: '',
                                value: '${_computeTotals(recipe, 'kcal')} kcal',
                                color: AppColors.accentTurquoise,
                                enableGlow: true,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: MacroPill(
                                label: 'P',
                                value: '${_computeTotals(recipe, 'protein')}g',
                                color: AppColors.accentMint,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: MacroPill(
                                label: 'C',
                                value: '${_computeTotals(recipe, 'carbs')}g',
                                color: AppColors.accentTurquoise,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: MacroPill(
                                label: 'F',
                                value: '${_computeTotals(recipe, 'fat')}g',
                                color: AppColors.accentAmber,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: recipes.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .extension<AppBrandTheme>()
                        ?.outline
                        .withOpacity(0.3) ??
                        Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRouter.nutritionRecipeEdit),
                tooltip: 'Gericht erstellen',
                child: const BrandGradientIcon(Icons.add_rounded, size: 28),
              ),
            )
          : null,
    );
  }
}
