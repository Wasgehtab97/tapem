import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/providers/report_provider.dart';
import 'package:tapem/features/report/presentation/widgets/calendar_heatmap.dart';
import 'package:tapem/core/widgets/heatmap_widget.dart';
import '../../providers/report_providers.dart' as report_providers;
import '../widgets/device_usage_chart.dart';
import '../widgets/usage_key_metrics.dart';
import '../widgets/usage_device_list.dart';

class ReportUsageScreen extends ConsumerWidget {
  final String gymId;

  const ReportUsageScreen({super.key, required this.gymId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportProvider = ref.watch(report_providers.reportProvider);
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    if (reportProvider.shouldLoadReport(gymId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(report_providers.reportProvider).loadReport(gymId);
        await ref.read(report_providers.reportProvider).loadHeatmapDates();
      });
    } else if (reportProvider.heatmapDates.isEmpty &&
        reportProvider.currentGymId == gymId) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(report_providers.reportProvider).loadHeatmapDates();
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(loc.reportUsageTitle),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: brandColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              Color.alphaBlend(
                brandColor.withOpacity(0.05),
                theme.scaffoldBackgroundColor,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                // Date Range Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: DeviceUsageRange.values.map((range) {
                      final isSelected = reportProvider.usageRange == range;
                      String label;
                      switch (range) {
                        case DeviceUsageRange.last7Days:
                          label = '7 Tage';
                          break;
                        case DeviceUsageRange.last30Days:
                          label = '30 Tage';
                          break;
                        case DeviceUsageRange.last90Days:
                          label = '90 Tage';
                          break;
                        case DeviceUsageRange.last365Days:
                          label = 'Jahr';
                          break;
                        case DeviceUsageRange.all:
                          label = 'Gesamt';
                          break;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              reportProvider.changeUsageRange(range);
                            }
                          },
                          selectedColor: brandColor.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? brandColor : theme.colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: theme.colorScheme.surface,
                          side: BorderSide(
                            color: isSelected ? brandColor : theme.colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // Key Metrics
                UsageKeyMetrics(
                  stats: reportProvider.usageStats,
                  range: reportProvider.usageRange,
                ),
                
                const SizedBox(height: AppSpacing.xl),

                // Heatmap / Stoßzeiten
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    'Aktivitäts-Heatmap',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: reportProvider.heatmapDates.isEmpty
                      ? Text(
                          'Noch keine Log-Daten für die Heatmap im ausgewählten Zeitraum.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CalendarHeatmap(
                              dates: reportProvider.heatmapDates,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _WeeklyPatternHeatmap(
                              dates: reportProvider.heatmapDates,
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: AppSpacing.xl),
                
                // Chart
                DeviceUsageChart(
                  usageData: reportProvider.usageStats,
                  state: reportProvider.state,
                  errorMessage: reportProvider.errorMessage,
                  usageRange: reportProvider.usageRange,
                  onRangeSelected: reportProvider.changeUsageRange,
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Detailed List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    'Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: UsageDeviceList(stats: reportProvider.usageStats),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeklyPatternHeatmap extends StatelessWidget {
  const _WeeklyPatternHeatmap({required this.dates});

  final List<DateTime> dates;

  @override
  Widget build(BuildContext context) {
    if (dates.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const slotLabels = ['Morgen', 'Mittag', 'Abend'];
    const weekdayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    final counts = List.generate(
      7,
      (_) => List<int>.filled(3, 0),
    );

    for (final dt in dates) {
      final local = dt.toLocal();
      final weekdayIndex = (local.weekday + 6) % 7; // 0=Mo,6=So
      final hour = local.hour;
      int? slot;
      if (hour >= 6 && hour < 12) {
        slot = 0; // Morgen
      } else if (hour >= 12 && hour < 18) {
        slot = 1; // Mittag
      } else if (hour >= 18 && hour < 22) {
        slot = 2; // Abend
      }
      if (slot != null) {
        counts[weekdayIndex][slot] += 1;
      }
    }

    int maxCount = 0;
    for (final row in counts) {
      for (final value in row) {
        if (value > maxCount) {
          maxCount = value;
        }
      }
    }
    if (maxCount == 0) {
      return Text(
        'Zu den typischen Trainingszeiten liegen noch keine Daten vor.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      );
    }

    final values = counts
        .map(
          (row) => row
              .map(
                (value) => value == 0 ? 0.0 : value / maxCount,
              )
              .toList(),
        )
        .toList();

    int bestWeekday = 0;
    int bestSlot = 0;
    for (var i = 0; i < counts.length; i++) {
      for (var j = 0; j < counts[i].length; j++) {
        if (counts[i][j] > counts[bestWeekday][bestSlot]) {
          bestWeekday = i;
          bestSlot = j;
        }
      }
    }

    final summary =
        'Stärkste Auslastung: ${weekdayLabels[bestWeekday]} ${slotLabels[bestSlot]}.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Muster nach Wochentag & Tageszeit',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weekdayLabels
                    .map(
                      (label) => SizedBox(
                        height: 24,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            label,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            HeatmapWidget(
              values: values,
              cellSize: 20,
              onCellTap: (row, col, value) {
                final count = counts[row][col];
                final label =
                    '${weekdayLabels[row]} ${slotLabels[col]}: $count Sessions';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(label)),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: slotLabels
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          summary,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
