import 'package:flutter/material.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/app_router.dart';
import 'package:url_launcher/url_launcher.dart';

class NutritionHomeScreen extends StatelessWidget {
  const NutritionHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
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
                    loc.homeTabNutrition,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    loc.nutritionHomeSubtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryCTA(
                          label: loc.nutritionScanCta,
                          icon: Icons.qr_code_scanner,
                          onPressed: () => Navigator.of(context)
                              .pushNamed(AppRouter.nutritionScan),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: SecondaryCTA(
                          label: loc.nutritionAddEntryCta,
                          icon: Icons.add,
                          onPressed: () => Navigator.of(context)
                              .pushNamed(AppRouter.nutritionEntry),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            NutritionSectionTitle(title: loc.nutritionEntriesTitle),
            NutritionCard(
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouter.nutritionGoals),
              child: Row(
                children: [
                  const Icon(Icons.tune),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.nutritionHomeGoalsTitle,
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          loc.nutritionHomeGoalsSubtitle,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            NutritionCard(
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouter.nutritionDay),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.nutritionDayTitle,
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          loc.nutritionHomeSubtitle,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            NutritionCard(
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouter.nutritionCalendar),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.nutritionHomeCalendarTitle,
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          loc.nutritionHomeCalendarSubtitle,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            NutritionSectionTitle(title: loc.nutritionAttributionTitle),
            NutritionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.nutritionAttributionBody,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      TextButton(
                        onPressed: () => launchUrl(
                          Uri.parse('https://world.openfoodfacts.org/'),
                        ),
                        child: Text(loc.nutritionAttributionSourceLink),
                      ),
                      TextButton(
                        onPressed: () => launchUrl(
                          Uri.parse(
                              'https://opendatacommons.org/licenses/odbl/1-0/'),
                        ),
                        child: Text(loc.nutritionAttributionLicenseLink),
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
