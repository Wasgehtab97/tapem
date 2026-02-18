import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/app_chip.dart';
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
      appBar: AppBar(
        title: Text(loc.reportUsageTitle),
        centerTitle: true,
        elevation: 0,
        foregroundColor: brandColor,
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
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

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AppChip(
                          label: _labelForRange(range, loc),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              reportProvider.changeUsageRange(range);
                            }
                          },
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
                    loc.reportUsageHeatmapTitle,
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
                          loc.reportUsageHeatmapEmpty,
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
                    loc.reportUsageDetailsTitle,
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
    final loc = AppLocalizations.of(context)!;

    final slotLabels = <String>[
      loc.reportUsageSlotMorning,
      loc.reportUsageSlotNoon,
      loc.reportUsageSlotEvening,
    ];
    final weekdayLabels = <String>[
      loc.reportUsageWeekdayMon,
      loc.reportUsageWeekdayTue,
      loc.reportUsageWeekdayWed,
      loc.reportUsageWeekdayThu,
      loc.reportUsageWeekdayFri,
      loc.reportUsageWeekdaySat,
      loc.reportUsageWeekdaySun,
    ];

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
        loc.reportUsagePatternEmpty,
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

    final summary = loc.reportUsagePatternPeakSummary(
      weekdayLabels[bestWeekday],
      slotLabels[bestSlot],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.reportUsagePatternTitle,
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
                final label = loc.reportUsagePatternCellLabel(
                  weekdayLabels[row],
                  slotLabels[col],
                  count,
                );
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

String _labelForRange(DeviceUsageRange range, AppLocalizations loc) {
  switch (range) {
    case DeviceUsageRange.last7Days:
      return loc.reportUsageRange7Days;
    case DeviceUsageRange.last30Days:
      return loc.reportUsageRange30Days;
    case DeviceUsageRange.last90Days:
      return loc.reportUsageRange90Days;
    case DeviceUsageRange.last365Days:
      return loc.reportUsageRange365Days;
    case DeviceUsageRange.all:
      return loc.reportUsageRangeAll;
  }
}
