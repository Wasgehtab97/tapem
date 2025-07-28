import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../survey.dart';
import '../../survey_provider.dart';

class SurveyDetailScreen extends StatefulWidget {
  final String gymId;
  final Survey survey;
  const SurveyDetailScreen({Key? key, required this.gymId, required this.survey})
      : super(key: key);

  @override
  State<SurveyDetailScreen> createState() => _SurveyDetailScreenState();
}

class _SurveyDetailScreenState extends State<SurveyDetailScreen> {
  late Future<Map<String, int>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = context.read<SurveyProvider>().getResults(
          gymId: widget.gymId,
          surveyId: widget.survey.id,
          options: widget.survey.options,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.survey.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ergebnisse',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<Map<String, int>>(
                future: _resultsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final results = snapshot.data!;
                  final total = results.values.fold<int>(0, (s, v) => s + v);
                  return ListView(
                    children: results.keys.map((option) {
                      final count = results[option] ?? 0;
                      final percent = total == 0 ? 0.0 : count / total;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(option,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: percent,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade700,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percent < 0.6
                                    ? const Color(0xFF00E676)
                                    : percent < 0.9
                                        ? const Color(0xFF00BCD4)
                                        : const Color(0xFFFFC107),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('$count Stimmen (${(percent * 100).toStringAsFixed(1)}%)'),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (widget.survey.open)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Umfrage abschließen'),
                  onPressed: () async {
                    await context.read<SurveyProvider>().closeSurvey(
                          gymId: widget.gymId,
                          surveyId: widget.survey.id,
                        );
                    Navigator.pop(context);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
