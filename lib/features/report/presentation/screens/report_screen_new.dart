import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/device_usage_chart.dart';
import '../../../feedback/presentation/screens/feedback_overview_screen.dart';
import '../../../feedback/feedback_provider.dart';

class ReportScreenNew extends StatelessWidget {
  final String gymId;

  const ReportScreenNew({Key? key, required this.gymId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, int> usageData = _exampleUsageData(context);
    final feedbackProvider = context.watch<FeedbackProvider>();
    if (!feedbackProvider.isLoading &&
        feedbackProvider.entries.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<FeedbackProvider>().loadFeedback(gymId);
      });
    }
    final int openCount = feedbackProvider.openEntries.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DeviceUsageChart(usageData: usageData),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.feedback_outlined),
                title: const Text('Feedback'),
                subtitle: Text(openCount > 0
                    ? '$openCount offene Einträge'
                    : 'Kein offenes Feedback'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FeedbackOverviewScreen(gymId: gymId),
                    ),
                  );
                },
              ),
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
}
