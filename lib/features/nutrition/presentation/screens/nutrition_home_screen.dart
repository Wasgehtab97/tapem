import 'package:flutter/material.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_overview_card.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/app_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/nutrition/providers/nutrition_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

class NutritionHomeScreen extends ConsumerStatefulWidget {
  const NutritionHomeScreen({super.key, this.onExitToProfile});

  final VoidCallback? onExitToProfile;

  @override
  ConsumerState<NutritionHomeScreen> createState() =>
      _NutritionHomeScreenState();
}

class _NutritionHomeScreenState extends ConsumerState<NutritionHomeScreen> {
  void _handleBackPressed() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    widget.onExitToProfile?.call();
  }

  Widget? _buildLeadingBackButton() {
    final canPop = Navigator.of(context).canPop();
    if (!canPop && widget.onExitToProfile == null) {
      return null;
    }
    return IconButton(
      onPressed: _handleBackPressed,
      icon: const Icon(Icons.chevron_left_rounded),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadToday());
  }

  Future<void> _loadToday() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.userId;
    if (uid == null || uid.isEmpty) return;
    await ref.read(nutritionProvider).loadDay(uid, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accent =
        theme.extension<AppBrandTheme>()?.outline ??
        theme.colorScheme.secondary;
    final state = ref.watch(nutritionProvider);
    final goal = state.goal?.kcal ?? 0;
    final total = state.log?.total.kcal ?? 0;
    final date = state.selectedDate;
    final protein = state.log?.total.protein ?? 0;
    final carbs = state.log?.total.carbs ?? 0;
    final fat = state.log?.total.fat ?? 0;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: _buildLeadingBackButton(),
        title: Text(loc.homeTabNutrition),
        centerTitle: true,
        foregroundColor: accent,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.lg,
          ),
          children: [
            // Premium hero header card
            NutritionOverviewCard(
              date: date,
              goal: goal,
              total: total,
              protein: protein,
              carbs: carbs,
              fat: fat,
            ),
            const SizedBox(height: AppSpacing.md),

            // Action tiles with premium design
            NutritionActionTile(
              icon: Icons.bar_chart_rounded,
              title: 'Tagesübersicht',
              subtitle: 'Kalorien und Makros im Blick.',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouter.nutritionDay),
            ),
            NutritionActionTile(
              icon: Icons.tune_rounded,
              title: loc.nutritionHomeGoalsTitle,
              subtitle: 'Kalorien definieren.',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouter.nutritionGoals),
            ),
            NutritionActionTile(
              icon: Icons.monitor_weight_rounded,
              title: loc.nutritionHomeWeightTitle,
              subtitle: loc.nutritionHomeWeightSubtitle,
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouter.nutritionWeight),
            ),
            NutritionActionTile(
              icon: Icons.restaurant_menu_rounded,
              title: 'Gerichte',
              subtitle: 'Eigene Rezepte speichern und hinzufügen.',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouter.nutritionRecipes),
            ),
            NutritionActionTile(
              icon: Icons.calendar_month_rounded,
              title: loc.nutritionHomeCalendarTitle,
              subtitle: 'Tage unter/auf/über Ziel sehen.',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouter.nutritionCalendar),
            ),
            const SizedBox(height: AppSpacing.md),

            // Attribution section
            NutritionSectionTitle(title: loc.nutritionAttributionTitle),
            NutritionCard(
              neutral: true,
              enableGlow: false,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Produktdaten stammen aus Open Food Facts und stehen unter der Open Database License (ODbL) 1.0. Eine Namensnennung ist erforderlich.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _AttributionLink(
                        label: 'Open Food Facts',
                        url: 'https://world.openfoodfacts.org/',
                      ),
                      _AttributionLink(
                        label: 'ODbL 1.0',
                        url: 'https://opendatacommons.org/licenses/odbl/1-0/',
                      ),
                      _AttributionLink(
                        label: 'Lizenzdetails',
                        url:
                            'https://world.openfoodfacts.org/legal/licence#content',
                      ),
                    ],
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

class _AttributionLink extends StatelessWidget {
  final String label;
  final String url;

  const _AttributionLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final color = brand?.outline ?? theme.colorScheme.secondary;

    Future<void> openLink() async {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Link konnte nicht geöffnet werden: $label')),
        );
      }
    }

    return ActionChip(
      label: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          decoration: TextDecoration.underline,
          decorationColor: color.withOpacity(0.5),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.6),
      side: BorderSide(color: color.withOpacity(0.25)),
      onPressed: openLink,
      avatar: Icon(Icons.link_rounded, size: 16, color: color),
      pressElevation: 1,
      visualDensity: VisualDensity.compact,
    );
  }
}
