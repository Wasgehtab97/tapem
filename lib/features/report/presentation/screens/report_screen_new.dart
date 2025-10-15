import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/device_usage_chart.dart';
import '../../../feedback/presentation/screens/feedback_overview_screen.dart';
import '../../../feedback/feedback_provider.dart';
import '../../../survey/presentation/screens/survey_overview_screen.dart';
import '../../../survey/survey_provider.dart';
import '../../../survey/survey.dart';
import '../../../survey/presentation/widgets/create_survey_sheet.dart';
import '../../../../core/providers/report_provider.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/brand_action_tile.dart';
import '../../../../core/logging/elog.dart';
import '../../../../l10n/app_localizations.dart';

class ReportScreenNew extends StatefulWidget {
  final String gymId;

  const ReportScreenNew({Key? key, required this.gymId}) : super(key: key);

  @override
  State<ReportScreenNew> createState() => _ReportScreenNewState();
}

class _ReportScreenNewState extends State<ReportScreenNew> {
  bool _requestedInitialLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureReportLoaded();
  }

  @override
  void didUpdateWidget(covariant ReportScreenNew oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gymId != widget.gymId) {
      _requestedInitialLoad = false;
      _ensureReportLoaded();
    }
  }

  void _ensureReportLoaded() {
    if (_requestedInitialLoad) {
      return;
    }
    if (!mounted || widget.gymId.isEmpty) {
      return;
    }
    _requestedInitialLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReportProvider>().loadReport(widget.gymId);
      final feedback = context.read<FeedbackProvider>();
      if (!feedback.isLoading && feedback.entries.isEmpty) {
        feedback.loadFeedback(widget.gymId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final feedbackProvider = context.watch<FeedbackProvider>();
    final loc = AppLocalizations.of(context)!;
    final usageData = reportProvider.usageStats;
    final int openCount = feedbackProvider.openEntries.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (reportProvider.state == ReportState.loading)
              const LinearProgressIndicator(minHeight: 3),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: reportProvider.state == ReportState.loading ||
                                widget.gymId.isEmpty
                            ? null
                            : () => reportProvider.refresh(),
                        icon: const Icon(Icons.refresh),
                        label: Text(loc.reportRefreshButton),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DeviceUsageChart(
                      usageData: usageData,
                      state: reportProvider.state,
                      errorMessage: reportProvider.errorMessage,
                      usageRange: reportProvider.usageRange,
                      onRangeSelected: reportProvider.changeUsageRange,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    BrandActionTile(
                      leadingIcon: Icons.feedback_outlined,
                      title: loc.reportFeedbackCardTitle,
                      subtitle: openCount > 0
                          ? loc.reportFeedbackOpenEntries(openCount)
                          : loc.reportFeedbackNoOpenEntries,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FeedbackOverviewScreen(gymId: widget.gymId),
                          ),
                        );
                      },
                      variant: BrandActionTileVariant.gradient,
                      uiLogEvent: 'REPORT_CARD_RENDER',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    BrandActionTile(
                      leadingIcon: Icons.add_circle_outline,
                      title: loc.reportCreateSurveyTitle,
                      onTap: () => _showCreateSurveyDialog(context),
                      variant: BrandActionTileVariant.gradient,
                      uiLogEvent: 'REPORT_CARD_RENDER',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    BrandActionTile(
                      leadingIcon: Icons.poll,
                      title: loc.reportViewSurveysTitle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SurveyOverviewScreen(gymId: widget.gymId),
                          ),
                        );
                      },
                      variant: BrandActionTileVariant.gradient,
                      uiLogEvent: 'REPORT_CARD_RENDER',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSurveyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateSurveySheet(gymId: widget.gymId),
    );
  }
}
