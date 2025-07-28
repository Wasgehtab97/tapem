import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../survey_provider.dart';

class CreateSurveySheet extends StatefulWidget {
  final String gymId;
  const CreateSurveySheet({Key? key, required this.gymId}) : super(key: key);

  @override
  State<CreateSurveySheet> createState() => _CreateSurveySheetState();
}

class _CreateSurveySheetState extends State<CreateSurveySheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _optionController = TextEditingController();
  final List<String> _options = [];

  @override
  void dispose() {
    _titleController.dispose();
    _optionController.dispose();
    super.dispose();
  }

  void _addOption() {
    final txt = _optionController.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _options.add(txt);
    });
    _optionController.clear();
  }

  void _removeOption(String option) {
    setState(() {
      _options.remove(option);
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Titel eingeben')),
      );
      return;
    }
    if (_options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mindestens zwei Optionen angeben')),
      );
      return;
    }
    await context.read<SurveyProvider>().createSurvey(
      gymId: widget.gymId,
      title: title,
      options: List<String>.from(_options),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Umfrage gespeichert')),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom, left: 16, right: 16, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Neue Umfrage',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Titel'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _optionController,
                  decoration: const InputDecoration(labelText: 'Option'),
                  onSubmitted: (_) => _addOption(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addOption,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_options.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _options
                  .map(
                    (o) => Chip(
                      label: Text(o),
                      onDeleted: () => _removeOption(o),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Speichern'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
