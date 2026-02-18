import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../survey_provider.dart';
import '../../survey.dart';

class SurveyVoteScreen extends ConsumerStatefulWidget {
  final String gymId;
  final String userId;
  final VoidCallback? onExitToProfile;
  const SurveyVoteScreen({
    Key? key,
    required this.gymId,
    required this.userId,
    this.onExitToProfile,
  }) : super(key: key);

  @override
  ConsumerState<SurveyVoteScreen> createState() => _SurveyVoteScreenState();
}

class _SurveyVoteScreenState extends ConsumerState<SurveyVoteScreen> {
  void _handleBackPressed() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    widget.onExitToProfile?.call();
  }

  Widget? _buildLeadingBackButton() {
    final canPop = Navigator.of(context).canPop();
    if (!canPop && widget.onExitToProfile == null) {
      return null;
    }
    return IconButton(
      onPressed: _handleBackPressed,
      icon: const Icon(Icons.chevron_left_rounded),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(surveyProvider).listen(widget.gymId, subscriber: this);
    });
  }

  @override
  void dispose() {
    ref.read(surveyProvider).cancel(subscriber: this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(surveyProvider);
    final surveys = prov.openSurveys;
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: _buildLeadingBackButton(),
        title: Text(loc.surveyListTitle),
      ),
      body: surveys.isEmpty
          ? Center(child: Text(loc.surveyEmpty))
          : ListView.builder(
              itemCount: surveys.length,
              itemBuilder: (_, index) {
                final s = surveys[index];
                return ListTile(
                  title: Text(s.title),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _SurveyVoteDetailScreen(
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

class _SurveyVoteDetailScreen extends ConsumerStatefulWidget {
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
  ConsumerState<_SurveyVoteDetailScreen> createState() =>
      _SurveyVoteDetailScreenState();
}

class _SurveyVoteDetailScreenState
    extends ConsumerState<_SurveyVoteDetailScreen> {
  String? _selectedOption;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.survey.title)),
      body: _submitted
          ? Center(child: Text(loc.surveyThanks))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.surveySelectOptionPrompt,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: widget.survey.options.map((opt) {
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
                    onPressed: _selectedOption == null
                        ? null
                        : () async {
                            await ref
                                .read(surveyProvider)
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
                    child: Text(loc.commonSubmit),
                  ),
                ],
              ),
            ),
    );
  }
}
