// lib/features/report/presentation/screens/report_screen_new.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/report_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/premium_action_tile.dart';
import 'package:tapem/features/feedback/feedback_provider.dart'
    as feedback_riverpod;
import 'package:tapem/features/report/presentation/widgets/usage_key_metrics.dart';
import 'package:tapem/features/report/providers/report_providers.dart'
    as report_providers;
import 'package:tapem/features/survey/survey_provider.dart' as survey_riverpod;
import 'package:tapem/l10n/app_localizations.dart';

import 'report_feedback_screen.dart';
import 'report_members_screen.dart';
import 'report_surveys_screen.dart';
import 'report_usage_screen.dart';

class ReportScreenNew extends ConsumerWidget {
  final String gymId;
  final PreferredSizeWidget? appBar;

  const ReportScreenNew({Key? key, required this.gymId, this.appBar})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportProvider = ref.watch(report_providers.reportProvider);

    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    // Usage-Report lazy laden, sobald der Screen sichtbar wird.
    if (reportProvider.shouldLoadReport(gymId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(report_providers.reportProvider).loadReport(gymId);
      });
    }

    // Offene/abgeschlossene Umfragen anhören.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(survey_riverpod.surveyProvider).listen(gymId);
    });

    final usageStats = reportProvider.usageStats;
    final usageRange = reportProvider.usageRange;
    final feedbackState = ref.watch(feedback_riverpod.feedbackProvider);
    final surveyState = ref.watch(survey_riverpod.surveyProvider);
    final openFeedbackCount = feedbackState.openEntries.length;
    final openSurveysCount = surveyState.openSurveys.length;
    final closedSurveysCount = surveyState.closedSurveys.length;

    return Scaffold(
      appBar: appBar,
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(
                    'Kennzahlen zu Mitgliedern, Nutzung und Feedback.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Globaler Zeitraum-Selector für den Nutzungsreport
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: DeviceUsageRange.values.map((range) {
                      final isSelected = usageRange == range;
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
                              ref
                                  .read(report_providers.reportProvider)
                                  .changeUsageRange(range);
                            }
                          },
                          selectedColor: brandColor.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? brandColor
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          backgroundColor: theme.colorScheme.surface,
                          side: BorderSide(
                            color: isSelected
                                ? brandColor
                                : theme.colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Hero-KPIs auf Basis der Nutzungsdaten
                if (usageStats.isNotEmpty ||
                    reportProvider.state == ReportState.loading)
                  UsageKeyMetrics(stats: usageStats, range: usageRange),

                // Service-KPIs (Feedback & Umfragen)
                const SizedBox(height: AppSpacing.lg),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ReportChip(
                        label: 'Offenes Feedback',
                        value: '$openFeedbackCount',
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _ReportChip(
                        label: 'Umfragen',
                        value:
                            'Aktiv: $openSurveysCount · Abgeschlossen: $closedSurveysCount',
                      ),
                    ],
                  ),
                ),

                if (usageStats.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _ManagementSummary(
                    totalSessions: usageStats.fold<int>(
                      0,
                      (sum, item) => sum + item.sessions,
                    ),
                    topDeviceName:
                        (List.of(
                              usageStats,
                            )..sort((a, b) => b.sessions.compareTo(a.sessions)))
                            .first
                            .name,
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Navigations-Cards
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: PremiumActionTile(
                        leading: const Icon(Icons.groups_rounded),
                        title: loc.reportMembersButtonTitle,
                        subtitle: loc.reportMembersButtonSubtitle,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportMembersScreen(gymId: gymId),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: PremiumActionTile(
                        leading: const Icon(Icons.bar_chart_rounded),
                        title: loc.reportUsageButtonTitle,
                        subtitle: loc.reportUsageButtonSubtitle,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportUsageScreen(gymId: gymId),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: PremiumActionTile(
                        leading: const Icon(Icons.feedback_outlined),
                        title: loc.reportFeedbackButtonTitle,
                        subtitle: openFeedbackCount > 0
                            ? loc.reportFeedbackOpenEntries(openFeedbackCount)
                            : loc.reportFeedbackNoOpenEntries,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReportFeedbackScreen(gymId: gymId),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: PremiumActionTile(
                        leading: const Icon(Icons.poll),
                        title: loc.reportSurveysButtonTitle,
                        subtitle: openSurveysCount > 0 || closedSurveysCount > 0
                            ? 'Aktiv: $openSurveysCount · Abgeschlossen: $closedSurveysCount'
                            : loc.reportSurveysButtonSubtitle,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportSurveysScreen(gymId: gymId),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManagementSummary extends StatelessWidget {
  const _ManagementSummary({
    required this.totalSessions,
    required this.topDeviceName,
  });

  final int totalSessions;
  final String topDeviceName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final List<String> lines = [];
    if (totalSessions > 0) {
      lines.add(
        'In diesem Zeitraum wurden $totalSessions Sessions dokumentiert.',
      );
    } else {
      lines.add(
        'Für den aktuellen Zeitraum liegen noch keine Nutzungssessions vor.',
      );
    }
    if (topDeviceName.isNotEmpty) {
      lines.add('Am häufigsten genutzt: $topDeviceName.');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: onSurface.withOpacity(0.85),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportChip extends StatelessWidget {
  const _ReportChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
