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

class ReportScreenNew extends StatelessWidget {
  final String gymId;

  const ReportScreenNew({Key? key, required this.gymId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final usageData = context.watch<ReportProvider>().usageCounts;
    final feedbackProvider = context.watch<FeedbackProvider>();
    if (!feedbackProvider.isLoading && feedbackProvider.entries.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<FeedbackProvider>().loadFeedback(gymId);
      });
    }
    final int openCount = feedbackProvider.openEntries.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DeviceUsageChart(usageData: usageData),
            const SizedBox(height: AppSpacing.md),
            BrandActionTile(
              leadingIcon: Icons.feedback_outlined,
              title: 'Feedback',
              subtitle: openCount > 0
                  ? '$openCount offene Einträge'
                  : 'Kein offenes Feedback',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FeedbackOverviewScreen(gymId: gymId),
                  ),
                );
              },
              variant: BrandActionTileVariant.outlined,
              uiLogEvent: 'REPORT_CARD_RENDER',
            ),
            const SizedBox(height: AppSpacing.sm),
            BrandActionTile(
              leadingIcon: Icons.add_circle_outline,
              title: 'Umfrage erstellen',
              onTap: () => _showCreateSurveyDialog(context),
              variant: BrandActionTileVariant.outlined,
              uiLogEvent: 'REPORT_CARD_RENDER',
            ),
            const SizedBox(height: AppSpacing.sm),
            BrandActionTile(
              leadingIcon: Icons.poll,
              title: 'Umfragen ansehen',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SurveyOverviewScreen(gymId: gymId),
                  ),
                );
              },
              variant: BrandActionTileVariant.outlined,
              uiLogEvent: 'REPORT_CARD_RENDER',
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
      builder: (_) => CreateSurveySheet(gymId: gymId),
    );
  }
}
