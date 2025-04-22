// lib/screens/dashboard/multi_exercise_selector.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_controller.dart';

class MultiExerciseSelector extends StatelessWidget {
  const MultiExerciseSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Bitte wähle eine Übung:",
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          children: [
            for (var ex in ctrl.exerciseOptions)
              ChoiceChip(
                label: Text(ex),
                selected: ex == ctrl.selectedExercise,
                onSelected: (_) => ctrl.selectExercise(ex),
              ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Eigene Übung hinzufügen',
              onPressed: () {
                debugPrint("➕ + gedrückt – öffne Add‑Dialog");
                _showAddDialog(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showAddDialog(BuildContext ctx) {
    final input = TextEditingController();
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text("Eigene Übung hinzufügen"),
        content: TextField(
          controller: input,
          decoration: const InputDecoration(hintText: "Name der Übung"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Abbrechen"),
          ),
          TextButton(
            onPressed: () {
              final name = input.text.trim();
              debugPrint("📥 Dialog OK, name=$name");
              if (name.isNotEmpty) {
                ctx.read<DashboardController>().addCustomExercise(name);
              }
              Navigator.pop(c);
            },
            child: const Text("Hinzufügen"),
          ),
        ],
      ),
    );
  }
}
