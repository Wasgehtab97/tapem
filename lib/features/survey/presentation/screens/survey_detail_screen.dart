import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/widgets/destructive_action.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../survey.dart';
import '../../survey_provider.dart';

class SurveyDetailScreen extends ConsumerStatefulWidget {
  final String gymId;
  final Survey survey;
  const SurveyDetailScreen({
    Key? key,
    required this.gymId,
    required this.survey,
  }) : super(key: key);

  @override
  ConsumerState<SurveyDetailScreen> createState() => _SurveyDetailScreenState();
}

class _SurveyDetailScreenState extends ConsumerState<SurveyDetailScreen> {
  late Future<Map<String, int>> _resultsFuture;
  late bool _isSurveyOpen;

  @override
  void initState() {
    super.initState();
    _isSurveyOpen = widget.survey.open;
    _resultsFuture = ref
        .read(surveyProvider)
        .getResults(
          gymId: widget.gymId,
          surveyId: widget.survey.id,
          options: widget.survey.options,
        );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.survey.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.surveyResultsTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
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
                            Text(option, style: const TextStyle(fontSize: 16)),
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
                            Text(
                              loc.surveyVotesCountWithPercent(
                                count,
                                (percent * 100).toStringAsFixed(1),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (_isSurveyOpen)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.close),
                  label: Text(loc.surveyClose),
                  onPressed: () async {
                    final confirmed = await showDestructiveActionDialog(
                      context: context,
                      title: 'Umfrage abschließen?',
                      message:
                          'Mit dem Abschließen endet die Teilnahme für Mitglieder.',
                      confirmLabel: 'Abschließen',
                    );
                    if (!confirmed) {
                      return;
                    }
                    await ref
                        .read(surveyProvider)
                        .closeSurvey(
                          gymId: widget.gymId,
                          surveyId: widget.survey.id,
                        );
                    if (!mounted) return;
                    setState(() => _isSurveyOpen = false);
                    showUndoSnackBar(
                      context: context,
                      message: 'Umfrage wurde abgeschlossen.',
                      onUndo: () async {
                        await ref
                            .read(surveyProvider)
                            .reopenSurvey(
                              gymId: widget.gymId,
                              surveyId: widget.survey.id,
                            );
                        if (mounted) {
                          setState(() => _isSurveyOpen = true);
                        }
                      },
                      undoSuccessMessage: 'Umfrage wieder geöffnet.',
                      undoErrorPrefix: 'Rückgängig fehlgeschlagen',
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
