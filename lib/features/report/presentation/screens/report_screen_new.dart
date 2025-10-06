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

class ReportScreenNew extends StatelessWidget {
  final String gymId;

  const ReportScreenNew({Key? key, required this.gymId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final usageData = reportProvider.usageStats;
    final feedbackProvider = context.watch<FeedbackProvider>();
    final loc = AppLocalizations.of(context)!;
    if (!feedbackProvider.isLoading && feedbackProvider.entries.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<FeedbackProvider>().loadFeedback(gymId);
      });
    }
    final int openCount = feedbackProvider.openEntries.length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DeviceUsageChart(
                usageData: usageData,
                state: reportProvider.state,
                errorMessage: reportProvider.errorMessage,
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
                      builder: (_) => FeedbackOverviewScreen(gymId: gymId),
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
                      builder: (_) => SurveyOverviewScreen(gymId: gymId),
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
    );
  }

  void _showCreateSurveyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateSurveySheet(gymId: gymId),
    );
  }
}
