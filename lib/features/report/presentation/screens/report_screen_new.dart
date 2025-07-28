import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/device_usage_chart.dart';
import '../../../feedback/presentation/screens/feedback_overview_screen.dart';
import '../../../feedback/feedback_provider.dart';
import '../../../survey/presentation/screens/survey_overview_screen.dart';
import '../../../survey/survey_provider.dart';
import '../../../survey/survey.dart';
import '../../../../core/providers/report_provider.dart';

class ReportScreenNew extends StatelessWidget {
  final String gymId;

  const ReportScreenNew({Key? key, required this.gymId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final usageData = context.watch<ReportProvider>().usageCounts;
    final data = usageData.isEmpty ? _exampleUsageData(context) : usageData;
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
            DeviceUsageChart(usageData: data),
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
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: const Text('Umfrage erstellen'),
                    onTap: () => _showCreateSurveyDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.poll),
                    title: const Text('Umfragen ansehen'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SurveyOverviewScreen(gymId: gymId),
                        ),
                      );
                    },
                  ),
                ],
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

  void _showCreateSurveyDialog(BuildContext context) {
    final titleController = TextEditingController();
    final optionController = TextEditingController();
    final options = <String>[];

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Neue Umfrage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Titel'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: optionController,
                      decoration:
                          const InputDecoration(labelText: 'Option hinzufügen'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final txt = optionController.text.trim();
                      if (txt.isNotEmpty) {
                        options.add(txt);
                        optionController.clear();
                        (context as Element).markNeedsBuild();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  children: options
                      .map((e) => ListTile(title: Text(e)))
                      .toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isNotEmpty && options.length >= 2) {
                  await context.read<SurveyProvider>().createSurvey(
                        gymId: gymId,
                        title: title,
                        options: options,
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }
}
