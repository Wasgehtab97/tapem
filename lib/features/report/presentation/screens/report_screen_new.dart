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

class ReportScreenNew extends StatelessWidget {
  final String gymId;

  const ReportScreenNew({Key? key, required this.gymId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final usageData = context.watch<ReportProvider>().usageCounts;
    final data = usageData.isEmpty ? _exampleUsageData(context) : usageData;
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
            DeviceUsageChart(usageData: data),
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
            ),
            const SizedBox(height: AppSpacing.sm),
            BrandActionTile(
              leadingIcon: Icons.add_circle_outline,
              title: 'Umfrage erstellen',
              onTap: () => _showCreateSurveyDialog(context),
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
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _exampleUsageData(BuildContext context) {
    return {
      'Gerät A': 120,
      'Gerät B': 95,
      'Gerät C': 80,
      'Gerät D': 75,
      'Gerät E': 60,
      'Gerät F': 55,
      'Gerät G': 50,
      'Gerät H': 45,
      'Gerät I': 40,
      'Gerät J': 35,
      'Gerät K': 30,
      'Gerät L': 25,
      'Gerät M': 20,
      'Gerät N': 15,
      'Gerät O': 10,
      'Gerät P': 5,
    };
  }

  void _showCreateSurveyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateSurveySheet(gymId: gymId),
    );
  }
}
