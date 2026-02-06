import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/features/nutrition/providers/nutrition_provider.dart';
import 'package:tapem/features/nutrition/domain/utils/nutrition_dates.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_year_summary.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

class NutritionCalendarScreen extends ConsumerStatefulWidget {
  const NutritionCalendarScreen({super.key});

  @override
  ConsumerState<NutritionCalendarScreen> createState() =>
      _NutritionCalendarScreenState();
}

class _NutritionCalendarScreenState
    extends ConsumerState<NutritionCalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadYear());
  }

  Future<void> _loadYear() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.userId;
    if (uid == null || uid.isEmpty) return;
    final year = DateTime.now().year;
    await ref.read(nutritionProvider).loadYear(uid, year);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final state = ref.watch(nutritionProvider);
    final year = DateTime.now().year;
    final summary = state.yearSummary;

    return Scaffold(
      appBar: AppBar(title: Text(loc.nutritionCalendarTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        children: [
          // Intro text
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              right: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              loc.nutritionCalendarIntro,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ),
          if (state.isLoadingYear)
            const Center(child: CircularProgressIndicator())
          else ...[
            // Premium legend with brand gradients
            _LegendRow(),
            const SizedBox(height: AppSpacing.sm),
            // Month cards
            for (var month = 1; month <= 12; month++)
              _MonthCard(
                year: year,
                month: month,
                days: summary?.days ?? const {},
              ),
          ],
        ],
      ),
    );
  }
}

/// Premium legend with brand gradient chips
class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          _LegendChip(label: loc.nutritionLegendUnder, color: Colors.redAccent),
          _LegendChip(
            label: loc.nutritionLegendOn,
            color: AppColors.accentMint,
          ),
          _LegendChip(
            label: loc.nutritionLegendOver,
            color: AppColors.accentAmber,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 8,
            ),
            child: Text(
              loc.nutritionLegendHint,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.textTheme.labelSmall?.color?.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withOpacity(0.35), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Month card with brand interactive card wrapper
class _MonthCard extends StatelessWidget {
  final int year;
  final int month;
  final Map<String, NutritionYearDay> days;

  const _MonthCard({
    required this.year,
    required this.month,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final offset = (firstDay.weekday + 6) % 7; // Monday=0
    final totalCells = offset + daysInMonth;
    final monthLabel = DateFormat.MMMM(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(firstDay);

    return NutritionCard(
      enableGlow: false,
      padding: const EdgeInsets.all(AppSpacing.sm),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandGradientText(
            monthLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              if (index < offset) {
                return const SizedBox.shrink();
              }
              final day = index - offset + 1;
              final key = nutritionDateKeyFromParts(year, month, day);
              final summary = days[key];
              return _DayCell(day: day, summary: summary);
            },
          ),
        ],
      ),
    );
  }
}

/// Day cell with compact progress fill styling.
class _DayCell extends StatelessWidget {
  final int day;
  final NutritionYearDay? summary;

  const _DayCell({required this.day, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;
    final goal = summary?.goal ?? 0;
    final total = summary?.total ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        double ratio = 0;
        if (goal > 0) {
          ratio = (total / goal).clamp(0.0, 2.0);
        }
        final fillGreen = goal > 0 ? math.min(ratio, 1.0) : 0.0;
        final over = ratio > 1 ? math.min(ratio - 1.0, 1.0) : 0.0;
        final under = goal > 0 && ratio < 1 ? (1 - ratio) : 0.0;

        // Brand gradient colors
        final onTargetGradient = LinearGradient(
          colors: [AppColors.accentMint, AppColors.accentTurquoise],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: brandColor.withOpacity(0.15), width: 1),
          ),
          child: Stack(
            children: [
              // Green fill for on-target (brand gradient)
              if (fillGreen > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: height * fillGreen,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: onTargetGradient,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(6),
                      ),
                    ),
                  ),
                ),
              // Red over fill (amber gradient)
              if (over > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: height * over,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accentAmber, Colors.orange.shade700],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(6),
                      ),
                    ),
                  ),
                ),
              // Under target (red at top)
              if (under > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: height * under,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.25),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ),
                ),
              // Day number
              Center(
                child: Text(
                  '$day',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: goal > 0
                        ? Colors.white.withOpacity(0.9)
                        : theme.textTheme.labelSmall?.color?.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
