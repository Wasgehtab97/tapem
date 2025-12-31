import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/features/nutrition/providers/nutrition_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/app_router.dart';

class NutritionDayScreen extends ConsumerStatefulWidget {
  const NutritionDayScreen({super.key});

  @override
  ConsumerState<NutritionDayScreen> createState() => _NutritionDayScreenState();
}

class _NutritionDayScreenState extends ConsumerState<NutritionDayScreen> {
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
    final state = ref.watch(nutritionProvider);
    final date = state.selectedDate;
    final dateLabel = DateFormat.yMMMd().format(date);
    final total = state.log?.total;
    final goal = state.goal;
    final targetKcal = goal?.kcal ?? 0;
    final totalKcal = total?.kcal ?? 0;
    final progress = targetKcal <= 0 ? 0.0 : (totalKcal / targetKcal).clamp(0.0, 1.0);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.nutritionDayTitle),
        actions: [
          IconButton(
            tooltip: loc.nutritionChangeDateCta,
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(date.year - 1, 1, 1),
                lastDate: DateTime(date.year + 1, 12, 31),
              );
              if (picked == null || !mounted) return;
              final auth = ref.read(authControllerProvider);
              final uid = auth.userId;
              if (uid == null || uid.isEmpty) return;
              await ref.read(nutritionProvider).loadDay(uid, picked);
            },
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
                  Text(
                    dateLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${loc.nutritionTargetLabel}: $targetKcal kcal • ${loc.nutritionTotalLabel}: $totalKcal kcal',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor:
                          Colors.white.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: NutritionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.nutritionTargetLabel,
                            style: theme.textTheme.labelMedium),
                        const SizedBox(height: 6),
                        Text('$targetKcal kcal',
                            style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: NutritionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.nutritionTotalLabel,
                            style: theme.textTheme.labelMedium),
                        const SizedBox(height: 6),
                        Text('$totalKcal kcal',
                            style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (state.isLoadingDay)
              const Center(child: CircularProgressIndicator())
            else if ((state.log?.entries.isEmpty ?? true))
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  loc.nutritionEmptyEntries,
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else ...[
              NutritionSectionTitle(title: loc.nutritionEntriesTitle),
              for (final entry in state.log!.entries)
                NutritionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.name,
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          MacroPill(
                            label: 'P',
                            value: '${entry.protein} g',
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          MacroPill(
                            label: 'C',
                            value: '${entry.carbs} g',
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          MacroPill(
                            label: 'F',
                            value: '${entry.fat} g',
                            color: theme.colorScheme.tertiary ?? Colors.amber,
                          ),
                          const Spacer(),
                          Text(
                            '${entry.kcal} kcal',
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.md),
            PrimaryCTA(
              label: loc.nutritionAddEntryCta,
              icon: Icons.add,
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.nutritionEntry),
            ),
            const SizedBox(height: AppSpacing.xs),
            SecondaryCTA(
              label: loc.nutritionScanCta,
              icon: Icons.qr_code_scanner,
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.nutritionScan),
            ),
            const SizedBox(height: AppSpacing.xs),
            SecondaryCTA(
              label: loc.nutritionEditGoalCta,
              icon: Icons.tune,
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.nutritionGoals),
            ),
          ],
        ),
      ),
    );
  }
}
