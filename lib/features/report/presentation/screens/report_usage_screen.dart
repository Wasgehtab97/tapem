import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_brand_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/report_providers.dart' as report_providers;
import '../widgets/device_usage_chart.dart';

class ReportUsageScreen extends ConsumerWidget {
  final String gymId;

  const ReportUsageScreen({super.key, required this.gymId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportProvider = ref.watch(report_providers.reportProvider);
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;

    if (reportProvider.shouldLoadReport(gymId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(report_providers.reportProvider).loadReport(gymId);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.reportUsageTitle),
        centerTitle: true,
        foregroundColor: brandColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: DeviceUsageChart(
            usageData: reportProvider.usageStats,
            state: reportProvider.state,
            errorMessage: reportProvider.errorMessage,
            usageRange: reportProvider.usageRange,
            onRangeSelected: reportProvider.changeUsageRange,
          ),
        ),
      ),
    );
  }
}
