import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../survey_provider.dart';
import '../../survey.dart';

class SurveyVoteScreen extends StatefulWidget {
  final String gymId;
  final String userId;
  const SurveyVoteScreen({Key? key, required this.gymId, required this.userId})
    : super(key: key);

  @override
  State<SurveyVoteScreen> createState() => _SurveyVoteScreenState();
}

class _SurveyVoteScreenState extends State<SurveyVoteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SurveyProvider>().listen(widget.gymId);
    });
  }

  @override
  void dispose() {
    context.read<SurveyProvider>().cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SurveyProvider>();
    final surveys = prov.openSurveys;
    return Scaffold(
      appBar: AppBar(title: const Text('Umfragen')),
      body:
          surveys.isEmpty
              ? const Center(child: Text('Keine offenen Umfragen'))
              : ListView.builder(
                itemCount: surveys.length,
                itemBuilder: (_, index) {
                  final s = surveys[index];
                  return ListTile(
                    title: Text(s.title),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => _SurveyVoteDetailScreen(
                                  gymId: widget.gymId,
                                  survey: s,
                                  userId: widget.userId,
                                ),
                          ),
                        ),
                  );
                },
              ),
    );
  }
}

class _SurveyVoteDetailScreen extends StatefulWidget {
  final String gymId;
  final Survey survey;
  final String userId;
  const _SurveyVoteDetailScreen({
    Key? key,
    required this.gymId,
    required this.survey,
    required this.userId,
  }) : super(key: key);

  @override
  State<_SurveyVoteDetailScreen> createState() =>
      _SurveyVoteDetailScreenState();
}

class _SurveyVoteDetailScreenState extends State<_SurveyVoteDetailScreen> {
  String? _selectedOption;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.survey.title)),
      body:
          _submitted
              ? const Center(child: Text('Danke für deine Teilnahme!'))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bitte wähle eine Option:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children:
                            widget.survey.options.map((opt) {
                              return RadioListTile<String>(
                                title: Text(opt),
                                value: opt,
                                groupValue: _selectedOption,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedOption = value;
                                  });
                                },
                              );
                            }).toList(),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          _selectedOption == null
                              ? null
                              : () async {
                                await context
                                    .read<SurveyProvider>()
                                    .submitAnswer(
                                      gymId: widget.gymId,
                                      surveyId: widget.survey.id,
                                      userId: widget.userId,
                                      selectedOption: _selectedOption!,
                                    );
                                setState(() {
                                  _submitted = true;
                                });
                              },
                      child: const Text('Absenden'),
                    ),
                  ],
                ),
              ),
    );
  }
}
