// lib/screens/dashboard/exercise_selector.dart

import 'package:flutter/material.dart';

class ExerciseSelector extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final void Function(String) onSelect;
  final VoidCallback onAddCustom;

  const ExerciseSelector({
    Key? key,
    required this.options,
    this.selected,
    required this.onSelect,
    required this.onAddCustom,
  }) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return Column(
      children: [
        Text("Bitte Übung wählen", style: Theme.of(ctx).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            for (var opt in options)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: opt == selected ? Theme.of(ctx).colorScheme.secondary : null),
                onPressed: () => onSelect(opt),
                child: Text(opt),
              ),
            IconButton(icon: const Icon(Icons.add), onPressed: onAddCustom),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
