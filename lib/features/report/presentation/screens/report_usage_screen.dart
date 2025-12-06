import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/providers/report_provider.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(report_providers.reportProvider).loadReport(gymId);
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
