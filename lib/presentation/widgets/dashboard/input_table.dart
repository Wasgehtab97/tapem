// lib/presentation/widgets/dashboard/input_table.dart

import 'package:flutter/material.dart';
import 'package:tapem/domain/models/exercise_entry.dart';

/// Zeigt bestehende Einträge und erlaubt das Hinzufügen neuer Sätze.
class InputTable extends StatefulWidget {
  final List<ExerciseEntry> entries;
  final void Function(
    String exercise,
    int sets,
    double weight,
    int reps,
  ) onAddSet;

  const InputTable({
    Key? key,
    required this.entries,
    required this.onAddSet,
  }) : super(key: key);

  @override
  State<InputTable> createState() => _InputTableState();
}

class _InputTableState extends State<InputTable> {
  final _exerciseCtrl = TextEditingController();
  final _setsCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();

  @override
  void dispose() {
    _exerciseCtrl.dispose();
    _setsCtrl.dispose();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Liste der bisherigen Sets
        for (final e in widget.entries) ...[
          ListTile(
            title: Text(e.exercise),
            subtitle: Text(
              '${e.sets}× ${e.weight.toStringAsFixed(1)} kg, '
              '${e.reps} Wdh. am '
              '${e.trainingDate != null ? '${e.trainingDate!.day.toString().padLeft(2, '0')}.' : ''}'
              '${e.trainingDate != null ? '${e.trainingDate!.month.toString().padLeft(2, '0')}.' : ''}'
              '${e.trainingDate?.year ?? ''}',
            ),
          ),
          const Divider(),
        ],

        // Formular für neuen Satz
        TextField(
          controller: _exerciseCtrl,
          decoration: const InputDecoration(labelText: 'Übung'),
        ),
        TextField(
          controller: _setsCtrl,
          decoration: const InputDecoration(labelText: 'Sätze'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _weightCtrl,
          decoration: const InputDecoration(labelText: 'Gewicht (kg)'),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        TextField(
          controller: _repsCtrl,
          decoration: const InputDecoration(labelText: 'Wiederholungen'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            final ex = _exerciseCtrl.text.trim();
            final sets = int.tryParse(_setsCtrl.text) ?? 0;
            final w = double.tryParse(_weightCtrl.text) ?? 0;
            final r = int.tryParse(_repsCtrl.text) ?? 0;
            if (ex.isNotEmpty && sets > 0 && w > 0 && r > 0) {
              widget.onAddSet(ex, sets, w, r);
              _exerciseCtrl.clear();
              _setsCtrl.clear();
              _weightCtrl.clear();
              _repsCtrl.clear();
            }
          },
          child: const Text('Satz hinzufügen'),
        ),
      ],
    );
  }
}
